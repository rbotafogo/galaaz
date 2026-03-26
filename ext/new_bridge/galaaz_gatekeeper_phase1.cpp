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
#include <string>
#include <sys/socket.h>
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
  std::string read_str_tag(uint8_t c) {
    if (c >= 0xa0 && c <= 0xbf) return str(c & 0x1f);
    if (c == 0xd9) return str(u8());
    if (c == 0xda) return str(be16());
    if (c == 0xdb) return str(be32());
    Rcpp::stop("msgpack: expected string");
  }

  void skip_one() {
    uint8_t c = u8();
    if (c == 0xc0 || c == 0xc2 || c == 0xc3) return;
    if (c >= 0x00 && c <= 0x7f) return;
    if (c >= 0xe0) return;
    if (c >= 0xa0 && c <= 0xbf) {
      i += c & 0x1f;
      return;
    }
    if (c == 0xd9) {
      i += u8();
      return;
    }
    if (c == 0xda) {
      i += be16();
      return;
    }
    if (c == 0xdb) {
      i += be32();
      return;
    }
    if (c == 0xcc || c == 0xd0) {
      u8();
      return;
    }
    if (c == 0xcd || c == 0xd1) {
      be16();
      return;
    }
    if (c == 0xce || c == 0xd2) {
      be32();
      return;
    }
    if (c == 0xcf || c == 0xd3 || c == 0xcb) {
      i += 8;
      return;
    }
    if (c >= 0x90 && c <= 0x9f) {
      size_t n = c & 0x0f;
      for (size_t k = 0; k < n; k++) skip_one();
      return;
    }
    if (c == 0xdc) {
      size_t n = be16();
      for (size_t k = 0; k < n; k++) skip_one();
      return;
    }
    if (c == 0xdd) {
      size_t n = be32();
      for (size_t k = 0; k < n; k++) skip_one();
      return;
    }
    if (c >= 0x80 && c <= 0x8f) {
      size_t n = c & 0x0f;
      for (size_t k = 0; k < n; k++) {
        skip_one();
        skip_one();
      }
      return;
    }
    if (c == 0xde) {
      size_t n = be16();
      for (size_t k = 0; k < n; k++) {
        skip_one();
        skip_one();
      }
      return;
    }
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
  void parse_envelope(std::map<std::string, std::string>& f, std::map<std::string, bool>& nils) {
    uint8_t c = u8();
    size_t n = 0;
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
      if (vt == 0xc0) {
        u8();
        nils[key] = true;
      } else if (vt >= 0xa0 && vt <= 0xbf || vt == 0xd9 || vt == 0xda || vt == 0xdb) {
        f[key] = read_str_tag(u8());
      } else if (vt >= 0x00 && vt <= 0x7f) {
        f[key] = std::to_string(static_cast<int>(u8()));
      } else if (vt >= 0xe0) {
        f[key] = std::to_string(static_cast<int>(static_cast<int8_t>(u8())));
      } else if (vt == 0xcc) {
        u8();
        f[key] = std::to_string(static_cast<unsigned>(u8()));
      } else if (vt == 0xce) {
        u8();
        uint32_t x = be32();
        f[key] = std::to_string(x);
      } else if (vt == 0xd2) {
        u8();
        int32_t x = static_cast<int32_t>((static_cast<uint32_t>(u8()) << 24) | (static_cast<uint32_t>(u8()) << 16) |
                                          (static_cast<uint32_t>(u8()) << 8) | u8());
        f[key] = std::to_string(x);
      } else if (vt == 0xcb) {
        u8();
        double v;
        std::memcpy(&v, d.data() + i, 8);
        i += 8;
        f[key] = std::to_string(v);
      } else if (vt == 0xc3) {
        u8();
        f[key] = "TRUE";
      } else if (vt == 0xc2) {
        u8();
        f[key] = "FALSE";
      } else {
        skip_one();
        f[key] = "";
      }
    }
  }
};

// MsgPack pack helpers for the specific envelope shapes we emit.
void pack_str(std::vector<uint8_t>& o, const std::string& s) {
  size_t n = s.size();
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

void pack_map5(std::vector<uint8_t>& o) { o.push_back(static_cast<uint8_t>(0x80 | 5)); }

void pack_map6(std::vector<uint8_t>& o) { o.push_back(static_cast<uint8_t>(0x80 | 6)); }

void pack_map4(std::vector<uint8_t>& o) { o.push_back(static_cast<uint8_t>(0x80 | 4)); }

// Build a CALL envelope (R -> Ruby callback request).
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
std::vector<uint8_t> make_ret(const std::string& call_id, const std::string& status, const std::string& payload,
                              const std::string& instance_id) {
  std::vector<uint8_t> o;
  pack_map6(o);
  pack_str(o, "call_id");
  pack_str(o, call_id);
  pack_str(o, "type");
  pack_str(o, "RET");
  pack_str(o, "status");
  pack_str(o, status);
  pack_str(o, "payload");
  pack_str(o, payload);
  pack_str(o, "instance_id");
  pack_str(o, instance_id);
  pack_str(o, "parent_id");
  pack_nil(o);
  return o;
}

// Escape a string for embedding into a small JSON literal.
std::string json_escape(const std::string& s) {
  std::string o;
  for (char c : s) {
    if (c == '"' || c == '\\')
      o += '\\';
    o += c;
  }
  return o;
}

// Resolve or create the per-session environment for sid.
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

// Evaluate one R expression and return a compact JSON payload:
//   {"kind":"integer|double|logical|character","value":...}
// or {"kind":"error","message":"..."}.
//
// Current protocol intentionally supports only length-1 scalar results.
std::string eval_code_json(const std::string& code, const Rcpp::Environment& env) {
  ParseStatus ps = PARSE_OK;
  SEXP px = R_ParseVector(Rf_mkString(code.c_str()), 1, &ps, R_GlobalEnv);
  if (ps != PARSE_OK)
    return std::string("{\"kind\":\"error\",\"message\":\"") + json_escape("parse error") + "\"}";
  SEXP expr = VECTOR_ELT(px, 0);
  int err = 0;
  SEXP val = R_tryEval(expr, env, &err);
  if (err) {
    return "{\"kind\":\"error\",\"message\":\"evaluation error\"}";
  }
  if (Rf_length(val) != 1)
    return "{\"kind\":\"error\",\"message\":\"phase1 requires length-1 scalar\"}";

  if (TYPEOF(val) == INTSXP) {
    int x = INTEGER(val)[0];
    if (x == NA_INTEGER) return "{\"kind\":\"integer\",\"value\":null}";
    return "{\"kind\":\"integer\",\"value\":" + std::to_string(x) + "}";
  }
  if (TYPEOF(val) == REALSXP) {
    double x = REAL(val)[0];
    if (R_IsNA(x)) return "{\"kind\":\"double\",\"value\":null}";
    return "{\"kind\":\"double\",\"value\":" + std::to_string(x) + "}";
  }
  if (TYPEOF(val) == LGLSXP) {
    int x = LOGICAL(val)[0];
    if (x == NA_LOGICAL) return "{\"kind\":\"logical\",\"value\":null}";
    return std::string("{\"kind\":\"logical\",\"value\":") + (x ? "true" : "false") + "}";
  }
  if (TYPEOF(val) == STRSXP) {
    if (STRING_ELT(val, 0) == NA_STRING) return "{\"kind\":\"character\",\"value\":null}";
    const char* s = CHAR(STRING_ELT(val, 0));
    if (!s) return "{\"kind\":\"character\",\"value\":null}";
    std::string out = s;
    return std::string("{\"kind\":\"character\",\"value\":\"") + json_escape(out) + "\"}";
  }
  return "{\"kind\":\"error\",\"message\":\"unsupported type\"}";
}

// Forward declaration for nested REQ servicing.
static void process_single_req(int fd, const std::map<std::string, std::string>& fields, Rcpp::Environment& g);

// [[Rcpp::export(name="galaaz_callback_call_phase3")]]
// R-side callback trampoline:
//   - Sends CALL envelope to Ruby.
//   - Waits for matching RET for call_id.
//   - While waiting, processes nested inbound REQ envelopes.
double galaaz_callback_call(std::string call_id, std::string payload, int timeout_ms) {
  if (g_bridge_fd < 0) Rcpp::stop("galaaz_callback_call: no active bridge connection");

  // Send CALL envelope to Ruby.
  auto call = make_call(call_id, payload, g_current_instance_id);
  dbg(std::string("TX CALL call_id=") + call_id + " instance_id=" + g_current_instance_id + " payload=" + payload);
  uint32_t L = static_cast<uint32_t>(call.size());
  if (!send_all(g_bridge_fd, &L, 4) || !send_all(g_bridge_fd, call.data(), call.size())) {
    Rcpp::stop("galaaz_callback_call: socket write failed");
  }

  // Phase 4: Nested wait loop - service REQs while waiting for callback RET
  Rcpp::Environment g = Rcpp::Environment::global_env();
  auto start_time = std::chrono::steady_clock::now();
  int remaining_ms = timeout_ms;

  for (;;) {
    // Poll with remaining timeout
    if (timeout_ms > 0) {
      pollfd pfd;
      pfd.fd = g_bridge_fd;
      pfd.events = POLLIN;
      pfd.revents = 0;
      int pr = ::poll(&pfd, 1, remaining_ms);
      if (pr < 0) Rcpp::stop("galaaz_callback_call: poll error");
      if (pr == 0) Rcpp::stop("galaaz_callback_call timeout");
    }

    // Read frame
    uint32_t len = 0;
    if (!recv_all(g_bridge_fd, &len, 4)) Rcpp::stop("galaaz_callback_call: socket closed");
    if (len > 64u * 1024u * 1024u) Rcpp::stop("galaaz_callback_call: frame too large");

    std::vector<uint8_t> buf(len);
    if (len && !recv_all(g_bridge_fd, buf.data(), len)) Rcpp::stop("galaaz_callback_call: truncated frame");

    // Parse envelope
    std::map<std::string, std::string> fields;
    std::map<std::string, bool> nils;
    Rd rd(buf);
    rd.parse_envelope(fields, nils);

    std::string msg_type = fields.count("type") ? fields["type"] : "";

    // Check if this is our callback RET
    if (msg_type == "RET" && fields["call_id"] == call_id) {
      std::string status = fields.count("status") ? fields["status"] : "error";
      std::string out_payload = fields.count("payload") ? fields["payload"] : "";
      dbg(std::string("RX RET status=") + status + " payload=" + out_payload);
      if (status != "success") {
        Rcpp::stop(out_payload.c_str());
      }
      char* end = nullptr;
      const char* start = out_payload.c_str();
      double v = std::strtod(start, &end);
      if (end == start) Rcpp::stop("galaaz_callback_call: payload not numeric");
      return v;
    }

    // Service nested REQ while waiting
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
      continue;  // Keep waiting for callback RET
    }

    // Unexpected message type - log and continue waiting
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
    std::string j = eval_code_json(code, env);
    bool ok = j.find("\"kind\":\"error\"") == std::string::npos;
    auto ret = make_ret(call_id, ok ? "success" : "error", j, iid);
    uint32_t L = static_cast<uint32_t>(ret.size());
    if (!send_all(fd, &L, 4) || !send_all(fd, ret.data(), ret.size())) {
      dbg("process_single_req: send failed");
    }
  } catch (...) {
    auto ret = make_ret(call_id, "error", "{\"kind\":\"error\",\"message\":\"cpp/r error\"}", iid);
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
      auto er = make_ret("?", "error", "{\"kind\":\"error\",\"message\":\"bad envelope\"}", "default");
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
