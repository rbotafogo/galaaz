// -----------------------------------------------------------------------------
// galaaz_gatekeeper_phase1.cpp
//
// Gatekeeper runtime loaded inside the R process. It is the R-side half of the
// NewBridge protocol and is responsible for:
//
//   1) Opening a TCP connection from R -> Ruby.
//   2) Reading framed MsgPack envelopes from Ruby.
//   3) Evaluating REQ payloads in a per-session R environment.
//   4) Writing RET envelopes back to Ruby (JSON payload, success/error status).
//   5) During callbacks, servicing nested REQ traffic while waiting for RET.
//
// -----------------------------------------------------------------------------
// High-level protocol
//
// Ruby sends:  [uint32 length][msgpack envelope bytes]
// R reads and parses envelope fields:
//   - call_id
//   - type        ("REQ" / "RET" / "CALL")
//   - session_id
//   - instance_id
//   - payload
//   - parent_id (optional nil)
//
// R executes payload code and returns RET:
//   status="success" with JSON scalar payload, OR
//   status="error"   with JSON error payload.
//
// -----------------------------------------------------------------------------
// Session model
//
// Each session_id maps to a dedicated R environment in .galaaz_sessions. This
// provides isolation for user variables across concurrent sessions while still
// inheriting from global env for base functions/operators.
//
// -----------------------------------------------------------------------------
// Callback model
//
// galaaz_callback_call() is called by R code to invoke Ruby callbacks. While
// waiting for callback RET, it runs a nested service loop that continues to
// process inbound REQ messages. This avoids deadlocks in recursive callback
// scenarios (Ruby -> R -> Ruby -> R ...).
//
// POSIX sockets only (Linux/macOS/WSL).
// -----------------------------------------------------------------------------

#include <Rcpp.h>
#include <arpa/inet.h>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <map>
#include <netdb.h>
#include <netinet/in.h>
#include <poll.h>
#include <sstream>
#include <string>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <vector>

// Active bridge socket used by main loop and callback path.
static int g_bridge_fd = -1;
// Instance id of the currently serviced REQ; reused by callback CALL messages.
static std::string g_current_instance_id = "default";

// Raise an R exception with a stable gatekeeper prefix.
void die(const char* m) { Rcpp::stop("galaaz_run_bridge: %s", m); }

// Whether debug logging is enabled (GALAAZ_DEBUG != "0").
bool dbg_on() {
  const char* e = std::getenv("GALAAZ_DEBUG");
  return e && std::string(e) != "0";
}

// Emit debug messages to R console.
void dbg(const std::string& msg) {
  if (!dbg_on()) return;
  Rcpp::Rcout << "[galaaz_gatekeeper_phase1] " << msg << std::endl;
  Rcpp::Rcout.flush();
}

// Read exactly n bytes from socket; false on EOF/error.
bool recv_all(int fd, void* buf, size_t n) {
  auto* p = static_cast<char*>(buf);
  size_t g = 0;
  while (g < n) {
    ssize_t r = ::recv(fd, p + g, n - g, 0);
    if (r <= 0) return false;
    g += static_cast<size_t>(r);
  }
  return true;
}

// Write exactly n bytes to socket; false on EOF/error.
bool send_all(int fd, const void* buf, size_t n) {
  auto* p = static_cast<const char*>(buf);
  size_t s = 0;
  while (s < n) {
    ssize_t w = ::send(fd, p + s, n - s, 0);
    if (w <= 0) return false;
    s += static_cast<size_t>(w);
  }
  return true;
}

// Minimal MsgPack reader used only by bridge envelopes.
// Supports maps, strings, nil, basic scalar types, and recursive skip.
struct Rd {
  const std::vector<uint8_t>& d;
  size_t i;
  explicit Rd(const std::vector<uint8_t>& x) : d(x), i(0) {}
  uint8_t u8() {
    if (i >= d.size()) Rcpp::stop("msgpack truncated");
    return d[i++];
  }
  uint16_t be16() { return (static_cast<uint16_t>(u8()) << 8) | u8(); }
  uint32_t be32() {
    return (static_cast<uint32_t>(u8()) << 24) | (static_cast<uint32_t>(u8()) << 16) |
           (static_cast<uint32_t>(u8()) << 8) | u8();
  }
  std::string str(size_t n) {
    if (i + n > d.size()) Rcpp::stop("msgpack str truncated");
    std::string s(reinterpret_cast<const char*>(d.data() + i), n);
    i += n;
    return s;
  }
  // Decode a MsgPack string given its already-read type tag.
  //
  // Tags used here:
  // - 0xa0..0xbf : fixstr  (length embedded in low 5 bits)
  // - 0xd9       : str8    (next 1 byte is length)
  // - 0xda       : str16   (next 2 bytes are length, big-endian)
  // - 0xdb       : str32   (next 4 bytes are length, big-endian)
  //
  // We branch directly on tag values instead of a generic decoder because the
  // bridge protocol only needs these string forms; this keeps parsing compact.
  std::string read_str_tag(uint8_t c) {
    if (c >= 0xa0 && c <= 0xbf) return str(c & 0x1f);
    if (c == 0xd9) return str(u8());
    if (c == 0xda) return str(be16());
    if (c == 0xdb) return str(be32());
    Rcpp::stop("msgpack: expected string");
  }

  // Skip exactly one MsgPack value (whatever its type), advancing cursor `i`.
  //
  // Why this exists:
  // - Our envelope parser only needs a subset of fields and scalar forms.
  // - Unknown keys/complex payloads should still be consumed safely.
  // - Skipping by wire format is cheaper than fully decoding to R objects.
  //
  // MsgPack tag groups used below (hex):
  //   c0=nil, c2=false, c3=true
  //   00..7f=positive fixint, e0..ff=negative fixint
  //   a0..bf=fixstr, d9=str8, da=str16, db=str32
  //   cc/cd/ce/cf=uint8/16/32/64, d0/d1/d2/d3=int8/16/32/64
  //   cb=float64
  //   90..9f=fixarray, dc=array16, dd=array32
  //   80..8f=fixmap, de=map16, df=map32
  //
  // The order intentionally checks tiny fixed-size tags first (fast common
  // path), then length-prefixed scalars, then recursive container types.
  void skip_one() {
    uint8_t c = u8();
    // nil / bool consume only the tag byte.
    if (c == 0xc0 || c == 0xc2 || c == 0xc3) return;
    // positive fixint: value encoded in tag itself.
    if (c >= 0x00 && c <= 0x7f) return;
    // negative fixint: value encoded in tag itself.
    if (c >= 0xe0) return;
    // fixstr: low 5 bits carry payload length.
    if (c >= 0xa0 && c <= 0xbf) {
      i += c & 0x1f;
      return;
    }
    // str8: next byte is string length.
    if (c == 0xd9) {
      i += u8();
      return;
    }
    // str16: next 2 bytes are length.
    if (c == 0xda) {
      i += be16();
      return;
    }
    // str32: next 4 bytes are length.
    if (c == 0xdb) {
      i += be32();
      return;
    }
    // uint8 / int8: one payload byte.
    if (c == 0xcc || c == 0xd0) {
      u8();
      return;
    }
    // uint16 / int16: two payload bytes.
    if (c == 0xcd || c == 0xd1) {
      be16();
      return;
    }
    // uint32 / int32: four payload bytes.
    if (c == 0xce || c == 0xd2) {
      be32();
      return;
    }
    // uint64 / int64 / float64: eight payload bytes.
    if (c == 0xcf || c == 0xd3 || c == 0xcb) {
      i += 8;
      return;
    }
    // fixarray: low 4 bits carry element count, then recursively skip elements.
    if (c >= 0x90 && c <= 0x9f) {
      size_t n = c & 0x0f;
      for (size_t k = 0; k < n; k++) skip_one();
      return;
    }
    // array16: next 2 bytes carry element count.
    if (c == 0xdc) {
      size_t n = be16();
      for (size_t k = 0; k < n; k++) skip_one();
      return;
    }
    // array32: next 4 bytes carry element count.
    if (c == 0xdd) {
      size_t n = be32();
      for (size_t k = 0; k < n; k++) skip_one();
      return;
    }
    // fixmap: low 4 bits carry pair count; skip key then value for each pair.
    if (c >= 0x80 && c <= 0x8f) {
      size_t n = c & 0x0f;
      for (size_t k = 0; k < n; k++) {
        skip_one();
        skip_one();
      }
      return;
    }
    // map16: next 2 bytes carry pair count.
    if (c == 0xde) {
      size_t n = be16();
      for (size_t k = 0; k < n; k++) {
        skip_one();
        skip_one();
      }
      return;
    }
    // map32: next 4 bytes carry pair count.
    if (c == 0xdf) {
      size_t n = be32();
      for (size_t k = 0; k < n; k++) {
        skip_one();
        skip_one();
      }
      return;
    }
    Rcpp::stop("msgpack skip unsupported 0x%02x", c);
  }

  // Parse envelope map into:
  //   f[key]    -> string-encoded scalar value (or empty for skipped complex)
  //   nils[key] -> true if MsgPack value is nil
  // Keys must be strings.
  //
  // This decoder is intentionally selective:
  // - It eagerly decodes only scalar tags we currently use in envelopes.
  // - It skips unsupported/complex values with skip_one(), preserving stream
  //   alignment without paying object-construction cost.
  // - Storing scalar values as strings keeps downstream dispatch simple.
  void parse_envelope(std::map<std::string, std::string>& f, std::map<std::string, bool>& nils) {
    uint8_t c = u8();
    size_t n = 0;
    // Envelope root must be a map: fixmap/map16/map32.
    if (c >= 0x80 && c <= 0x8f)
      n = c & 0x0f;
    else if (c == 0xde)
      n = be16();
    else if (c == 0xdf)
      n = be32();
    else
      Rcpp::stop("msgpack: not a map");

    for (size_t j = 0; j < n; j++) {
      uint8_t kt = u8();
      std::string key = read_str_tag(kt);
      if (i >= d.size()) Rcpp::stop("msgpack: missing val");
      uint8_t vt = d[i];
      // nil
      if (vt == 0xc0) {
        u8();
        nils[key] = true;
      // string tags (fixstr/str8/str16/str32)
      } else if (vt >= 0xa0 && vt <= 0xbf || vt == 0xd9 || vt == 0xda || vt == 0xdb) {
        f[key] = read_str_tag(u8());
      // positive fixint
      } else if (vt >= 0x00 && vt <= 0x7f) {
        f[key] = std::to_string(static_cast<int>(u8()));
      // negative fixint
      } else if (vt >= 0xe0) {
        f[key] = std::to_string(static_cast<int>(static_cast<int8_t>(u8())));
      // uint8
      } else if (vt == 0xcc) {
        u8();
        f[key] = std::to_string(static_cast<unsigned>(u8()));
      // uint32
      } else if (vt == 0xce) {
        u8();
        uint32_t x = be32();
        f[key] = std::to_string(x);
      // int32
      } else if (vt == 0xd2) {
        u8();
        int32_t x = static_cast<int32_t>((static_cast<uint32_t>(u8()) << 24) | (static_cast<uint32_t>(u8()) << 16) |
                                          (static_cast<uint32_t>(u8()) << 8) | u8());
        f[key] = std::to_string(x);
      // float64
      } else if (vt == 0xcb) {
        u8();
        double v;
        std::memcpy(&v, d.data() + i, 8);
        i += 8;
        f[key] = std::to_string(v);
      // true
      } else if (vt == 0xc3) {
        u8();
        f[key] = "TRUE";
      // false
      } else if (vt == 0xc2) {
        u8();
        f[key] = "FALSE";
      } else {
        // Unknown/complex value: skip bytes so next key-value pair is aligned.
        skip_one();
        f[key] = "";
      }
    }
  }
};

// MsgPack pack helpers for the specific envelope shapes we emit.
// They intentionally support only what the bridge writes on the wire.
void pack_str(std::vector<uint8_t>& o, const std::string& s) {
  size_t n = s.size();
  // Choose the smallest legal string encoding:
  // - fixstr (< 32 bytes) = 1-byte header
  // - str8   (< 256)      = 2-byte header
  // - str16  (otherwise)  = 3-byte header
  //
  // This keeps envelope size small and is faster than always using str32.
  if (n < 32)
    o.push_back(static_cast<uint8_t>(0xa0 | n));
  else if (n < 256) {
    o.push_back(0xd9);
    o.push_back(static_cast<uint8_t>(n));
  } else {
    o.push_back(0xda);
    o.push_back(static_cast<uint8_t>((n >> 8) & 0xff));
    o.push_back(static_cast<uint8_t>(n & 0xff));
  }
  o.insert(o.end(), s.begin(), s.end());
}

void pack_nil(std::vector<uint8_t>& o) { o.push_back(0xc0); }
void pack_true(std::vector<uint8_t>& o) { o.push_back(0xc3); }
void pack_false(std::vector<uint8_t>& o) { o.push_back(0xc2); }
void pack_bool(std::vector<uint8_t>& o, bool v) { v ? pack_true(o) : pack_false(o); }
void pack_int32(std::vector<uint8_t>& o, int32_t x) {
  o.push_back(0xd2);
  o.push_back(static_cast<uint8_t>((x >> 24) & 0xff));
  o.push_back(static_cast<uint8_t>((x >> 16) & 0xff));
  o.push_back(static_cast<uint8_t>((x >> 8) & 0xff));
  o.push_back(static_cast<uint8_t>(x & 0xff));
}
void pack_double64(std::vector<uint8_t>& o, double v) {
  o.push_back(0xcb);
  uint64_t bits = 0;
  std::memcpy(&bits, &v, 8);
  o.push_back(static_cast<uint8_t>((bits >> 56) & 0xff));
  o.push_back(static_cast<uint8_t>((bits >> 48) & 0xff));
  o.push_back(static_cast<uint8_t>((bits >> 40) & 0xff));
  o.push_back(static_cast<uint8_t>((bits >> 32) & 0xff));
  o.push_back(static_cast<uint8_t>((bits >> 24) & 0xff));
  o.push_back(static_cast<uint8_t>((bits >> 16) & 0xff));
  o.push_back(static_cast<uint8_t>((bits >> 8) & 0xff));
  o.push_back(static_cast<uint8_t>(bits & 0xff));
}

void pack_map5(std::vector<uint8_t>& o) { o.push_back(static_cast<uint8_t>(0x80 | 5)); }

void pack_map6(std::vector<uint8_t>& o) { o.push_back(static_cast<uint8_t>(0x80 | 6)); }

void pack_map4(std::vector<uint8_t>& o) { o.push_back(static_cast<uint8_t>(0x80 | 4)); }
void pack_map3(std::vector<uint8_t>& o) { o.push_back(static_cast<uint8_t>(0x80 | 3)); }
void pack_map2(std::vector<uint8_t>& o) { o.push_back(static_cast<uint8_t>(0x80 | 2)); }

// Build a CALL envelope (R -> Ruby callback request).
//
// Wire shape is intentionally fixed and tiny:
//   {call_id, type="CALL", payload, instance_id}
//
// Why fixed-order explicit writes (instead of generic map builder):
// - lower allocation overhead in hot callback paths,
// - no dynamic reflection/branching for field selection,
// - easier protocol auditing because bytes are deterministic.
std::vector<uint8_t> make_call(const std::string& call_id, const std::string& payload,
                               const std::string& instance_id) {
  std::vector<uint8_t> o;
  pack_map4(o);
  pack_str(o, "call_id");
  pack_str(o, call_id);
  pack_str(o, "type");
  pack_str(o, "CALL");
  pack_str(o, "payload");
  pack_str(o, payload);
  pack_str(o, "instance_id");
  pack_str(o, instance_id);
  return o;
}

// Build a RET envelope (R -> Ruby response).
//
// Wire shape:
//   {call_id, type="RET", status, payload, instance_id, parent_id=nil}
//
// We always include parent_id (currently nil) to keep envelope shape stable
// across phases; this avoids Ruby-side "missing key" branches and makes logs
// easier to compare between callback/non-callback flows.
std::vector<uint8_t> make_ret(const std::string& call_id, const std::string& status,
                              const std::vector<uint8_t>& payload_bytes, const std::string& instance_id) {
  std::vector<uint8_t> o;
  pack_map6(o);
  pack_str(o, "call_id");
  pack_str(o, call_id);
  pack_str(o, "type");
  pack_str(o, "RET");
  pack_str(o, "status");
  pack_str(o, status);
  pack_str(o, "payload");
  o.insert(o.end(), payload_bytes.begin(), payload_bytes.end());
  pack_str(o, "instance_id");
  pack_str(o, instance_id);
  pack_str(o, "parent_id");
  pack_nil(o);
  return o;
}

std::vector<uint8_t> payload_error(const std::string& msg) {
  std::vector<uint8_t> p;
  pack_map2(p);
  pack_str(p, "kind");
  pack_str(p, "error");
  pack_str(p, "message");
  pack_str(p, msg);
  return p;
}

struct EvalResult {
  bool ok;
  std::vector<uint8_t> payload;
};

std::vector<uint8_t> payload_unbox_walk(const std::string& status, int nodes, int max_depth) {
  std::vector<uint8_t> p;
  // { kind, status, nodes, max_depth }
  p.push_back(static_cast<uint8_t>(0x80 | 4));
  pack_str(p, "kind");
  pack_str(p, "unbox_walk");
  pack_str(p, "status");
  pack_str(p, status);
  pack_str(p, "nodes");
  pack_int32(p, nodes);
  pack_str(p, "max_depth");
  pack_int32(p, max_depth);
  return p;
}

void pack_array_header(std::vector<uint8_t>& o, uint32_t n) {
  if (n < 16) {
    o.push_back(static_cast<uint8_t>(0x90 | n));
  } else if (n <= 0xffff) {
    o.push_back(0xdc);
    o.push_back(static_cast<uint8_t>((n >> 8) & 0xff));
    o.push_back(static_cast<uint8_t>(n & 0xff));
  } else {
    o.push_back(0xdd);
    o.push_back(static_cast<uint8_t>((n >> 24) & 0xff));
    o.push_back(static_cast<uint8_t>((n >> 16) & 0xff));
    o.push_back(static_cast<uint8_t>((n >> 8) & 0xff));
    o.push_back(static_cast<uint8_t>(n & 0xff));
  }
}

std::vector<uint8_t> payload_unbox_materialize(const std::string& status, int nodes, int max_depth,
                                               const std::vector<uint8_t>& value_bytes) {
  std::vector<uint8_t> p;
  // { kind, status, nodes, max_depth, value }
  p.push_back(static_cast<uint8_t>(0x80 | 5));
  pack_str(p, "kind");
  pack_str(p, "unbox_materialize");
  pack_str(p, "status");
  pack_str(p, status);
  pack_str(p, "nodes");
  pack_int32(p, nodes);
  pack_str(p, "max_depth");
  pack_int32(p, max_depth);
  pack_str(p, "value");
  p.insert(p.end(), value_bytes.begin(), value_bytes.end());
  return p;
}

bool starts_with(const std::string& s, const std::string& prefix) {
  return s.size() >= prefix.size() && s.compare(0, prefix.size(), prefix) == 0;
}

std::string trim_copy(const std::string& s) {
  size_t b = 0;
  while (b < s.size() && (s[b] == ' ' || s[b] == '\t' || s[b] == '\n' || s[b] == '\r')) b++;
  size_t e = s.size();
  while (e > b && (s[e - 1] == ' ' || s[e - 1] == '\t' || s[e - 1] == '\n' || s[e - 1] == '\r')) e--;
  return s.substr(b, e - b);
}

bool valid_var_name(const std::string& name) {
  if (name.empty()) return false;
  for (size_t i = 0; i < name.size(); ++i) {
    char c = name[i];
    bool ok = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
    if (!ok) return false;
  }
  return true;
}

std::string class_or_typeof_string(SEXP x) {
  SEXP cls = Rf_getAttrib(x, R_ClassSymbol);
  if (TYPEOF(cls) == STRSXP && Rf_length(cls) > 0) {
    std::string out;
    for (R_xlen_t i = 0; i < XLENGTH(cls); ++i) {
      if (i > 0) out += " ";
      SEXP elt = STRING_ELT(cls, i);
      if (elt == NA_STRING) out += "NA";
      else out += CHAR(elt);
    }
    if (!out.empty()) return out;
  }
  // matrix: atomic vector + dim length 2 (same as is.matrix); ensures r_class is not
  // mis-reported as plain integer/numeric when class() is unavailable to the attrib read.
  {
    SEXP dim = Rf_getAttrib(x, R_DimSymbol);
    if (dim != R_NilValue && TYPEOF(dim) == INTSXP && Rf_xlength(dim) == 2) {
      return "matrix array";
    }
  }
  if (Rf_inherits(x, "array")) {
    return "array";
  }
  // Keep legacy class labels expected by Ruby Object.build for atomic vectors.
  switch (TYPEOF(x)) {
    case INTSXP: return "integer";
    case REALSXP: return "numeric";
    case LGLSXP: return "logical";
    case STRSXP: return "character";
    case VECSXP: return "list";
    case CLOSXP: return "function";
    case ENVSXP: return "environment";
    case SYMSXP: return "name";
    case EXPRSXP: return "expression";
    default: return std::string(Rf_type2char(TYPEOF(x)));
  }
}

EvalResult payload_eval_with_result(SEXP val, const std::string& var_name) {
  if (TYPEOF(val) == SYMSXP) {
    std::vector<uint8_t> p;
    pack_map2(p);
    pack_str(p, "type");
    pack_str(p, "scalar_symbol");
    pack_str(p, "value");
    pack_str(p, std::string(CHAR(PRINTNAME(val))));
    return {true, p};
  }

  if (Rf_length(val) == 1) {
    if (TYPEOF(val) == INTSXP) {
      std::vector<uint8_t> p;
      pack_map2(p);
      pack_str(p, "type");
      pack_str(p, "scalar_integer");
      pack_str(p, "value");
      int x = INTEGER(val)[0];
      if (x == NA_INTEGER) pack_nil(p);
      else pack_int32(p, x);
      return {true, p};
    }
    if (TYPEOF(val) == REALSXP) {
      std::vector<uint8_t> p;
      pack_map2(p);
      pack_str(p, "type");
      pack_str(p, "scalar_double");
      pack_str(p, "value");
      double x = REAL(val)[0];
      if (R_IsNA(x)) pack_nil(p);
      else pack_double64(p, x);
      return {true, p};
    }
    if (TYPEOF(val) == LGLSXP) {
      std::vector<uint8_t> p;
      pack_map2(p);
      pack_str(p, "type");
      pack_str(p, "scalar_logical");
      pack_str(p, "value");
      int x = LOGICAL(val)[0];
      if (x == NA_LOGICAL) pack_nil(p);
      else pack_bool(p, x != 0);
      return {true, p};
    }
    if (TYPEOF(val) == STRSXP) {
      std::vector<uint8_t> p;
      pack_map2(p);
      pack_str(p, "type");
      pack_str(p, "scalar_character");
      pack_str(p, "value");
      if (STRING_ELT(val, 0) == NA_STRING) {
        pack_nil(p);
      } else {
        pack_str(p, std::string(CHAR(STRING_ELT(val, 0))));
      }
      return {true, p};
    }
  }

  std::vector<uint8_t> p;
  pack_map3(p);
  pack_str(p, "type");
  pack_str(p, "handle");
  pack_str(p, "handle");
  pack_str(p, var_name);
  pack_str(p, "r_class");
  pack_str(p, class_or_typeof_string(val));
  return {true, p};
}

EvalResult eval_with_result_cmd(const std::string& cmd, const Rcpp::Environment& env) {
  const std::string prefix = "__G_EVAL_WITH_RESULT__";
  std::string assignment = trim_copy(cmd.substr(prefix.size()));
  if (assignment.empty()) return {false, payload_error("bad eval_with_result args")};

  if (starts_with(assignment, ".GlobalEnv$")) {
    assignment = assignment.substr(std::string(".GlobalEnv$").size());
  }
  size_t arrow = assignment.find("<-");
  if (arrow == std::string::npos) return {false, payload_error("bad eval_with_result assignment")};

  std::string var_name = trim_copy(assignment.substr(0, arrow));
  std::string expr_code = trim_copy(assignment.substr(arrow + 2));
  if (!valid_var_name(var_name) || expr_code.empty()) {
    return {false, payload_error("invalid eval_with_result assignment")};
  }

  ParseStatus ps = PARSE_OK;
  SEXP px = R_ParseVector(Rf_mkString(expr_code.c_str()), 1, &ps, R_GlobalEnv);
  if (ps != PARSE_OK) return {false, payload_error("parse error")};
  SEXP expr = VECTOR_ELT(px, 0);

  int err = 0;
  SEXP val = R_tryEval(expr, env, &err);
  if (err) {
    std::string msg = "evaluation error";
    try {
      Rcpp::Function geterr("geterrmessage");
      SEXP m = geterr();
      if (Rf_isString(m) && Rf_length(m) >= 1) {
        msg = Rcpp::as<std::string>(m);
      }
    } catch (...) {
    }
    return {false, payload_error(msg)};
  }

  Rf_defineVar(Rf_install(var_name.c_str()), val, env);
  return payload_eval_with_result(val, var_name);
}

EvalResult eval_unbox_walk_cmd(const std::string& cmd, const Rcpp::Environment& env) {
  // Format: __G_UNBOX_WALK__|<handle>|<max_depth>|<max_nodes>
  std::vector<std::string> parts;
  size_t start = 0;
  while (start <= cmd.size()) {
    size_t pos = cmd.find('|', start);
    if (pos == std::string::npos) pos = cmd.size();
    parts.push_back(cmd.substr(start, pos - start));
    start = pos + 1;
    if (pos == cmd.size()) break;
  }
  if (parts.size() != 4) return {false, payload_error("bad unbox_walk args")};

  std::string handle = parts[1];
  int max_depth = std::atoi(parts[2].c_str());
  int max_nodes = std::atoi(parts[3].c_str());
  if (handle.empty() || max_depth <= 0 || max_nodes <= 0) {
    return {false, payload_error("invalid unbox_walk params")};
  }

  SEXP sym = Rf_install(handle.c_str());
  SEXP root = Rf_findVar(sym, env);
  if (root == R_UnboundValue) return {false, payload_error("unbox_walk unknown handle")};

  std::vector<std::pair<SEXP, int>> stack;
  stack.reserve(1024);
  stack.push_back({root, 1});

  int nodes = 0;
  int maxd = 0;
  std::string status = "OK";

  while (!stack.empty()) {
    auto cur = stack.back();
    stack.pop_back();
    SEXP x = cur.first;
    int d = cur.second;

    nodes += 1;
    if (d > maxd) maxd = d;
    if (nodes > max_nodes) { status = "NODE"; break; }
    if (d > max_depth) { status = "DEPTH"; break; }

    if (x == R_NilValue) continue;
    if (TYPEOF(x) == VECSXP) {
      R_xlen_t n = XLENGTH(x);
      for (R_xlen_t i = n; i > 0; --i) {
        SEXP child = VECTOR_ELT(x, i - 1);
        stack.push_back({child, d + 1});
      }
    }
  }

  return {true, payload_unbox_walk(status, nodes, maxd)};
}

bool materialize_value(SEXP x, int depth, int max_depth, int max_nodes, int& nodes, int& maxd,
                       std::vector<uint8_t>& out, std::string& status) {
  nodes += 1;
  if (depth > maxd) maxd = depth;
  if (nodes > max_nodes) {
    status = "NODE";
    return false;
  }
  if (depth > max_depth) {
    status = "DEPTH";
    return false;
  }

  if (x == R_NilValue) {
    pack_nil(out);
    return true;
  }

  switch (TYPEOF(x)) {
    case VECSXP: {
      R_xlen_t n = XLENGTH(x);
      pack_array_header(out, static_cast<uint32_t>(n));
      for (R_xlen_t i = 0; i < n; ++i) {
        if (!materialize_value(VECTOR_ELT(x, i), depth + 1, max_depth, max_nodes, nodes, maxd, out, status)) {
          return false;
        }
      }
      return true;
    }
    case INTSXP: {
      R_xlen_t n = XLENGTH(x);
      if (n == 1) {
        int v = INTEGER(x)[0];
        if (v == NA_INTEGER) pack_nil(out);
        else pack_int32(out, v);
      } else {
        pack_array_header(out, static_cast<uint32_t>(n));
        for (R_xlen_t i = 0; i < n; ++i) {
          int v = INTEGER(x)[i];
          if (v == NA_INTEGER) pack_nil(out);
          else pack_int32(out, v);
        }
      }
      return true;
    }
    case REALSXP: {
      R_xlen_t n = XLENGTH(x);
      if (n == 1) {
        double v = REAL(x)[0];
        if (R_IsNA(v)) pack_nil(out);
        else pack_double64(out, v);
      } else {
        pack_array_header(out, static_cast<uint32_t>(n));
        for (R_xlen_t i = 0; i < n; ++i) {
          double v = REAL(x)[i];
          if (R_IsNA(v)) pack_nil(out);
          else pack_double64(out, v);
        }
      }
      return true;
    }
    case LGLSXP: {
      R_xlen_t n = XLENGTH(x);
      if (n == 1) {
        int v = LOGICAL(x)[0];
        if (v == NA_LOGICAL) pack_nil(out);
        else pack_bool(out, v != 0);
      } else {
        pack_array_header(out, static_cast<uint32_t>(n));
        for (R_xlen_t i = 0; i < n; ++i) {
          int v = LOGICAL(x)[i];
          if (v == NA_LOGICAL) pack_nil(out);
          else pack_bool(out, v != 0);
        }
      }
      return true;
    }
    case STRSXP: {
      R_xlen_t n = XLENGTH(x);
      if (n == 1) {
        if (STRING_ELT(x, 0) == NA_STRING) pack_nil(out);
        else pack_str(out, std::string(CHAR(STRING_ELT(x, 0))));
      } else {
        pack_array_header(out, static_cast<uint32_t>(n));
        for (R_xlen_t i = 0; i < n; ++i) {
          if (STRING_ELT(x, i) == NA_STRING) pack_nil(out);
          else pack_str(out, std::string(CHAR(STRING_ELT(x, i))));
        }
      }
      return true;
    }
    default:
      status = "UNSUPPORTED";
      return false;
  }
}

EvalResult eval_unbox_materialize_cmd(const std::string& cmd, const Rcpp::Environment& env) {
  // Format: __G_UNBOX_MATERIALIZE__|<handle>|<max_depth>|<max_nodes>
  std::vector<std::string> parts;
  size_t start = 0;
  while (start <= cmd.size()) {
    size_t pos = cmd.find('|', start);
    if (pos == std::string::npos) pos = cmd.size();
    parts.push_back(cmd.substr(start, pos - start));
    start = pos + 1;
    if (pos == cmd.size()) break;
  }
  if (parts.size() != 4) return {false, payload_error("bad unbox_materialize args")};

  std::string handle = parts[1];
  int max_depth = std::atoi(parts[2].c_str());
  int max_nodes = std::atoi(parts[3].c_str());
  if (handle.empty() || max_depth <= 0 || max_nodes <= 0) {
    return {false, payload_error("invalid unbox_materialize params")};
  }

  SEXP sym = Rf_install(handle.c_str());
  SEXP root = Rf_findVar(sym, env);
  if (root == R_UnboundValue) return {false, payload_error("unbox_materialize unknown handle")};

  std::vector<uint8_t> value_bytes;
  int nodes = 0;
  int maxd = 0;
  std::string status = "OK";
  bool ok = materialize_value(root, 1, max_depth, max_nodes, nodes, maxd, value_bytes, status);
  if (!ok && status != "DEPTH" && status != "NODE" && status != "UNSUPPORTED") {
    status = "UNSUPPORTED";
  }
  // IMPORTANT: if traversal aborts (DEPTH/NODE/UNSUPPORTED), the recursive
  // encoder may have emitted only a prefix of a composite value (e.g. array
  // header without all declared elements). Returning that partial MsgPack blob
  // would make the outer RET payload undecodable on Ruby side and appear as a
  // broken connection. For non-OK statuses, force `value` to MsgPack nil so
  // envelope decoding always stays valid and status carries the reason.
  if (!ok) {
    value_bytes.clear();
    pack_nil(value_bytes);
  }

  return {true, payload_unbox_materialize(status, nodes, maxd, value_bytes)};
}

static bool valid_bridge_handle_token(const std::string& h) {
  if (h.size() < 5 || h.compare(0, 4, "g2_v") != 0) return false;
  for (size_t i = 4; i < h.size(); ++i) {
    if (h[i] < '0' || h[i] > '9') return false;
  }
  return true;
}

static bool valid_r_method_name_token(const std::string& n) {
  if (n.empty()) return false;
  for (size_t i = 0; i < n.size(); ++i) {
    char c = n[i];
    if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '.' || c == '_')) {
      return false;
    }
  }
  return true;
}

// MsgPack: { kind:"dispatch_probe", is_field:bool, is_func:bool }
// Mirrors the two Ruby-side probes in R::Support.process_missing_dispatch in one R eval.
std::vector<uint8_t> payload_dispatch_probe(bool is_field, bool is_func) {
  std::vector<uint8_t> p;
  pack_map3(p);
  pack_str(p, "kind");
  pack_str(p, "dispatch_probe");
  pack_str(p, "is_field");
  pack_bool(p, is_field);
  pack_str(p, "is_func");
  pack_bool(p, is_func);
  return p;
}

EvalResult eval_dispatch_probe_cmd(const std::string& cmd, const Rcpp::Environment& env) {
  // Format: __G_DISPATCH_PROBE__|<handle>|<name>
  std::vector<std::string> parts;
  size_t start = 0;
  while (start <= cmd.size()) {
    size_t pos = cmd.find('|', start);
    if (pos == std::string::npos) pos = cmd.size();
    parts.push_back(cmd.substr(start, pos - start));
    start = pos + 1;
    if (pos == cmd.size()) break;
  }
  if (parts.size() != 3) return {false, payload_error("bad dispatch_probe args")};
  if (parts[0] != "__G_DISPATCH_PROBE__") return {false, payload_error("bad dispatch_probe args")};

  std::string handle = trim_copy(parts[1]);
  std::string name = trim_copy(parts[2]);
  if (!valid_bridge_handle_token(handle) || !valid_r_method_name_token(name)) {
    return {false, payload_error("invalid dispatch_probe params")};
  }

  std::ostringstream oss;
  oss << "c(isTRUE('" << name << "' %in% names(" << handle << ")) || (is.environment(" << handle
      << ") && isTRUE(exists('" << name << "', envir = " << handle << ", inherits = FALSE))), "
      << "is.function(try(get('" << name << "'), silent=TRUE)))";

  ParseStatus ps = PARSE_OK;
  SEXP px = R_ParseVector(Rf_mkString(oss.str().c_str()), 1, &ps, R_GlobalEnv);
  if (ps != PARSE_OK) return {false, payload_error("dispatch_probe parse error")};
  SEXP expr = VECTOR_ELT(px, 0);
  int err = 0;
  SEXP val = R_tryEval(expr, env, &err);
  if (err) {
    std::string msg = "evaluation error";
    try {
      Rcpp::Function geterr("geterrmessage");
      SEXP m = geterr();
      if (Rf_isString(m) && Rf_length(m) >= 1) msg = Rcpp::as<std::string>(m);
    } catch (...) {
    }
    return {false, payload_error(msg)};
  }
  if (TYPEOF(val) != LGLSXP || Rf_length(val) < 2) {
    return {false, payload_error("dispatch_probe unexpected result")};
  }
  int a = LOGICAL(val)[0];
  int b = LOGICAL(val)[1];
  bool is_field = (a != 0 && a != NA_LOGICAL);
  bool is_func = (b != 0 && b != NA_LOGICAL);
  return {true, payload_dispatch_probe(is_field, is_func)};
}

// Resolve or create the per-session environment for sid.
//
// Why per-session environments:
// - isolation: variables from one session_id do not leak into another,
// - correctness under concurrency: each request executes in its own state bag,
// - low overhead: environments are lightweight and reused after first creation.
Rcpp::Environment session_env(Rcpp::Environment& g, const std::string& sid) {
  Rcpp::List sessions = Rcpp::as<Rcpp::List>(g[".galaaz_sessions"]);
  if (!sessions.containsElementNamed(sid.c_str())) {
    Rcpp::Function newenv("new.env");
    // Keep base/global operators visible while still storing user variables in this session's env.
    Rcpp::Environment e = newenv(Rcpp::Named("parent") = g);
    sessions[sid] = e;
    g[".galaaz_sessions"] = sessions;
  }
  return Rcpp::as<Rcpp::Environment>(sessions[sid]);
}

// Evaluate one R expression and return a compact MsgPack payload map:
//   {"kind":"integer|double|logical|character","value":...}
// or {"kind":"error","message":"..."}.
EvalResult eval_code_payload(const std::string& code, const Rcpp::Environment& env) {
  if (starts_with(code, "__G_EVAL_WITH_RESULT__")) {
    return eval_with_result_cmd(code, env);
  }
  if (starts_with(code, "__G_DISPATCH_PROBE__|")) {
    return eval_dispatch_probe_cmd(code, env);
  }
  if (starts_with(code, "__G_UNBOX_WALK__|")) {
    return eval_unbox_walk_cmd(code, env);
  }
  if (starts_with(code, "__G_UNBOX_MATERIALIZE__|")) {
    return eval_unbox_materialize_cmd(code, env);
  }
  ParseStatus ps = PARSE_OK;
  SEXP px = R_ParseVector(Rf_mkString(code.c_str()), 1, &ps, R_GlobalEnv);
  if (ps != PARSE_OK) return {false, payload_error("parse error")};
  SEXP expr = VECTOR_ELT(px, 0);
  int err = 0;
  SEXP val = R_tryEval(expr, env, &err);
  if (err) {
    // Preserve the underlying R exception message for better Ruby-side debugging.
    // `geterrmessage()` returns the most recent error string in the current R context.
    std::string msg = "evaluation error";
    try {
      Rcpp::Function geterr("geterrmessage");
      SEXP m = geterr();
      if (Rf_isString(m) && Rf_length(m) >= 1) {
        msg = Rcpp::as<std::string>(m);
      }
    } catch (...) {
      // Keep fallback message.
    }
    return {false, payload_error(msg)};
  }
  if (Rf_length(val) != 1) return {false, payload_error("phase1 requires length-1 scalar")};

  if (TYPEOF(val) == INTSXP) {
    std::vector<uint8_t> p;
    pack_map2(p);
    pack_str(p, "kind");
    pack_str(p, "integer");
    pack_str(p, "value");
    int x = INTEGER(val)[0];
    if (x == NA_INTEGER) pack_nil(p);
    else pack_int32(p, x);
    return {true, p};
  }
  if (TYPEOF(val) == REALSXP) {
    std::vector<uint8_t> p;
    pack_map2(p);
    pack_str(p, "kind");
    pack_str(p, "double");
    pack_str(p, "value");
    double x = REAL(val)[0];
    if (R_IsNA(x)) pack_nil(p);
    else pack_double64(p, x);
    return {true, p};
  }
  if (TYPEOF(val) == LGLSXP) {
    std::vector<uint8_t> p;
    pack_map2(p);
    pack_str(p, "kind");
    pack_str(p, "logical");
    pack_str(p, "value");
    int x = LOGICAL(val)[0];
    if (x == NA_LOGICAL) pack_nil(p);
    else pack_bool(p, x != 0);
    return {true, p};
  }
  if (TYPEOF(val) == STRSXP) {
    std::vector<uint8_t> p;
    pack_map2(p);
    pack_str(p, "kind");
    pack_str(p, "character");
    pack_str(p, "value");
    if (STRING_ELT(val, 0) == NA_STRING) {
      pack_nil(p);
      return {true, p};
    }
    const char* s = CHAR(STRING_ELT(val, 0));
    if (!s) {
      pack_nil(p);
      return {true, p};
    }
    pack_str(p, std::string(s));
    return {true, p};
  }
  return {false, payload_error("unsupported type")};
}

// Forward declaration for nested REQ servicing.
static void process_single_req(int fd, const std::map<std::string, std::string>& fields, Rcpp::Environment& g);

// R-side callback trampoline:
//   - Sends CALL envelope to Ruby.
//   - Waits for matching RET for call_id.
//   - While waiting, processes nested inbound REQ envelopes.
//
// Why nested servicing is required:
// If Ruby callback code re-enters R (directly or indirectly), the R side must
// continue processing REQ frames while blocked waiting for callback RET.
// Otherwise both sides can wait on each other (classic bridge deadlock).
// [[Rcpp::export(name="galaaz_callback_call_phase3")]]
double galaaz_callback_call(std::string call_id, std::string payload, int timeout_ms) {
  if (g_bridge_fd < 0) Rcpp::stop("galaaz_callback_call: no active bridge connection");

  // Send CALL envelope to Ruby.
  // Frame format: [uint32 length][msgpack bytes].
  auto call = make_call(call_id, payload, g_current_instance_id);
  dbg(std::string("TX CALL call_id=") + call_id + " instance_id=" + g_current_instance_id + " payload=" + payload);
  uint32_t L = static_cast<uint32_t>(call.size());
  if (!send_all(g_bridge_fd, &L, 4) || !send_all(g_bridge_fd, call.data(), call.size())) {
    Rcpp::stop("galaaz_callback_call: socket write failed");
  }

  // Phase 4: nested wait loop.
  // We stay in one loop so timeout accounting applies to both waiting and
  // nested work (REQ servicing), rather than treating them as separate clocks.
  Rcpp::Environment g = Rcpp::Environment::global_env();
  auto start_time = std::chrono::steady_clock::now();
  int remaining_ms = timeout_ms;

  for (;;) {
    // Poll with remaining timeout.
    // Using poll() avoids busy-spinning and lets timeout decrease precisely
    // across nested request handling.
    if (timeout_ms > 0) {
      pollfd pfd;
      pfd.fd = g_bridge_fd;
      pfd.events = POLLIN;
      pfd.revents = 0;
      int pr = ::poll(&pfd, 1, remaining_ms);
      if (pr < 0) Rcpp::stop("galaaz_callback_call: poll error");
      if (pr == 0) Rcpp::stop("galaaz_callback_call timeout");
    }

    // Read one complete framed message.
    uint32_t len = 0;
    if (!recv_all(g_bridge_fd, &len, 4)) Rcpp::stop("galaaz_callback_call: socket closed");
    if (len > 64u * 1024u * 1024u) Rcpp::stop("galaaz_callback_call: frame too large");

    std::vector<uint8_t> buf(len);
    if (len && !recv_all(g_bridge_fd, buf.data(), len)) Rcpp::stop("galaaz_callback_call: truncated frame");

    // Parse envelope into lightweight scalar maps (no full object materialize).
    std::map<std::string, std::string> fields;
    std::map<std::string, bool> nils;
    Rd rd(buf);
    rd.parse_envelope(fields, nils);

    std::string msg_type = fields.count("type") ? fields["type"] : "";

    // Fast-path: this is the RET corresponding to our callback call_id.
    if (msg_type == "RET" && fields["call_id"] == call_id) {
      std::string status = fields.count("status") ? fields["status"] : "error";
      std::string out_payload = fields.count("payload") ? fields["payload"] : "";
      dbg(std::string("RX RET status=") + status + " payload=" + out_payload);
      if (status != "success") {
        Rcpp::stop(out_payload.c_str());
      }
      // Phase-3 contract: callback payload is numeric text.
      // strtod is used for speed and predictable C parsing semantics.
      char* end = nullptr;
      const char* start = out_payload.c_str();
      double v = std::strtod(start, &end);
      if (end == start) Rcpp::stop("galaaz_callback_call: payload not numeric");
      return v;
    }

    // Service nested REQ while waiting for callback RET.
    // This is the deadlock-avoidance core.
    if (msg_type == "REQ") {
      dbg("Servicing nested REQ while waiting for callback RET");
      process_single_req(g_bridge_fd, fields, g);
      // Update remaining timeout
      if (timeout_ms > 0) {
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
          std::chrono::steady_clock::now() - start_time).count();
        remaining_ms = timeout_ms - static_cast<int>(elapsed);
        if (remaining_ms <= 0) Rcpp::stop("galaaz_callback_call timeout");
      }
      continue;  // Keep waiting for callback RET after nested work.
    }

    // Unexpected message type: ignore frame and continue waiting.
    // This keeps callback wait robust to protocol evolution/noise.
    dbg(std::string("Unexpected msg type while waiting for callback RET: ") + msg_type);
    if (timeout_ms > 0) {
      auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now() - start_time).count();
      remaining_ms = timeout_ms - static_cast<int>(elapsed);
      if (remaining_ms <= 0) Rcpp::stop("galaaz_callback_call timeout");
    }
  }
}

// Extern C forward declarations for .C() / dyn.load() compatibility.
extern "C" {
  void galaaz_run_bridge_c(const char** host, int* port);
  double galaaz_callback_call_phase3_c(const char** call_id, const char** payload, int* timeout_ms);
}

// Process a single REQ and send RET.
// This is shared by:
//   - main bridge loop
//   - nested callback wait loop
static void process_single_req(int fd, const std::map<std::string, std::string>& fields, Rcpp::Environment& g) {
  std::string call_id = fields.count("call_id") ? fields.at("call_id") : "?";
  std::string sid = fields.count("session_id") ? fields.at("session_id") : "default";
  std::string iid = fields.count("instance_id") ? fields.at("instance_id") : "default";
  std::string code = fields.count("payload") ? fields.at("payload") : "";

  try {
    g_current_instance_id = iid;
    Rcpp::Environment env = session_env(g, sid);
    EvalResult out = eval_code_payload(code, env);
    auto ret = make_ret(call_id, out.ok ? "success" : "error", out.payload, iid);
    uint32_t L = static_cast<uint32_t>(ret.size());
    if (!send_all(fd, &L, 4) || !send_all(fd, ret.data(), ret.size())) {
      dbg("process_single_req: send failed");
    }
  } catch (...) {
    auto ret = make_ret(call_id, "error", payload_error("cpp/r error"), iid);
    uint32_t L = static_cast<uint32_t>(ret.size());
    if (!send_all(fd, &L, 4) || !send_all(fd, ret.data(), ret.size())) {
      dbg("process_single_req: send failed (error path)");
    }
  }
}

// Main bridge loop entrypoint called from R:
//   galaaz_run_bridge(bridge_host, port)   # first arg: hostname or IPv4 string
//
// Connects to Ruby host, initializes session registry, then continuously:
//   - reads framed envelope
//   - parses MsgPack
//   - handles REQ via process_single_req
//   - sends protocol error RET for malformed envelopes
// [[Rcpp::export]]
void galaaz_run_bridge(std::string bridge_host, int port) {
  // Local Unix domain socket: port == 0 and bridge_host is an absolute path (e.g. /tmp/galaaz....sock).
  // Same MsgPack framing as TCP; lower overhead than loopback TCP on Linux/macOS.
  if (port == 0 && !bridge_host.empty() && bridge_host[0] == '/') {
    struct sockaddr_un addr;
    std::memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    if (bridge_host.size() >= sizeof(addr.sun_path)) {
      die("unix socket path too long");
    }
    std::memcpy(addr.sun_path, bridge_host.c_str(), bridge_host.size() + 1);
    int fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) die("socket(AF_UNIX)");
    if (::connect(fd, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) != 0) {
      ::close(fd);
      die("connect(AF_UNIX)");
    }
    g_bridge_fd = fd;

    Rcpp::Environment g = Rcpp::Environment::global_env();
    g[".galaaz_sessions"] = Rcpp::List();

    for (;;) {
      uint32_t len = 0;
      if (!recv_all(fd, &len, 4)) break;
      if (len > 64u * 1024u * 1024u) break;
      std::vector<uint8_t> buf(len);
      if (len && !recv_all(fd, buf.data(), len)) break;

      std::map<std::string, std::string> fields;
      std::map<std::string, bool> nils;
      try {
        Rd rd(buf);
        rd.parse_envelope(fields, nils);
      } catch (...) {
        auto er = make_ret("?", "error", payload_error("bad envelope"), "default");
        uint32_t L = static_cast<uint32_t>(er.size());
        if (!send_all(fd, &L, 4) || !send_all(fd, er.data(), er.size())) break;
        continue;
      }

      if (fields["type"] != "REQ") continue;
      process_single_req(fd, fields, g);
    }
    g_bridge_fd = -1;
    ::close(fd);
    return;
  }

  // Support both literal IPv4 and hostnames (e.g. host.docker.internal)
  // so containerized runtimes can connect back to Ruby host listener.
  addrinfo hints;
  std::memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  addrinfo* res = nullptr;
  std::string p = std::to_string(port);
  if (::getaddrinfo(bridge_host.c_str(), p.c_str(), &hints, &res) != 0) die("getaddrinfo");

  int fd = -1;
  for (addrinfo* it = res; it != nullptr; it = it->ai_next) {
    fd = ::socket(it->ai_family, it->ai_socktype, it->ai_protocol);
    if (fd < 0) continue;
    if (::connect(fd, it->ai_addr, it->ai_addrlen) == 0) break;
    ::close(fd);
    fd = -1;
  }
  ::freeaddrinfo(res);
  if (fd < 0) die("connect");
  g_bridge_fd = fd;

  Rcpp::Environment g = Rcpp::Environment::global_env();
  g[".galaaz_sessions"] = Rcpp::List();

  for (;;) {
    uint32_t len = 0;
    if (!recv_all(fd, &len, 4)) break;
    if (len > 64u * 1024u * 1024u) break;
    std::vector<uint8_t> buf(len);
    if (len && !recv_all(fd, buf.data(), len)) break;

    std::map<std::string, std::string> fields;
    std::map<std::string, bool> nils;
    try {
      Rd rd(buf);
      rd.parse_envelope(fields, nils);
    } catch (...) {
      auto er = make_ret("?", "error", payload_error("bad envelope"), "default");
      uint32_t L = static_cast<uint32_t>(er.size());
      if (!send_all(fd, &L, 4) || !send_all(fd, er.data(), er.size())) break;
      continue;
    }

    if (fields["type"] != "REQ") continue;
    process_single_req(fd, fields, g);
  }
  g_bridge_fd = -1;
  ::close(fd);
}

// C wrappers for .C() calls:
// R passes character vectors as char** and integers as int*.
extern "C" void galaaz_run_bridge_c(const char** host, int* port) {
  galaaz_run_bridge(std::string(*host), *port);
}

extern "C" double galaaz_callback_call_phase3_c(const char** call_id, const char** payload, int* timeout_ms) {
  return galaaz_callback_call(std::string(*call_id), std::string(*payload), *timeout_ms);
}
