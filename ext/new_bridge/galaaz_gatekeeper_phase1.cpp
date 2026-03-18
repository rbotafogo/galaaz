// Phase 1: R connects to Ruby (TCP client); read framed MsgPack REQ, eval in per-session env, write RET.
// POSIX sockets only (Linux/macOS/WSL).

#include <Rcpp.h>
#include <arpa/inet.h>
#include <cstdint>
#include <cstring>
#include <map>
#include <netinet/in.h>
#include <string>
#include <sys/socket.h>
#include <unistd.h>
#include <vector>

namespace {

void die(const char* m) { Rcpp::stop("galaaz_run_bridge: %s", m); }

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

  // Parse envelope map: keys are strings; values string or nil (parent_id).
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

std::vector<uint8_t> make_ret(const std::string& call_id, const std::string& status, const std::string& payload) {
  std::vector<uint8_t> o;
  pack_map5(o);
  pack_str(o, "call_id");
  pack_str(o, call_id);
  pack_str(o, "type");
  pack_str(o, "RET");
  pack_str(o, "status");
  pack_str(o, status);
  pack_str(o, "payload");
  pack_str(o, payload);
  pack_str(o, "parent_id");
  pack_nil(o);
  return o;
}

std::string json_escape(const std::string& s) {
  std::string o;
  for (char c : s) {
    if (c == '"' || c == '\\')
      o += '\\';
    o += c;
  }
  return o;
}

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
  return "{\"kind\":\"error\",\"message\":\"unsupported type\"}";
}

} // namespace

// [[Rcpp::export]]
void galaaz_run_bridge(std::string host, int port) {
  int fd = ::socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) die("socket");
  sockaddr_in a;
  std::memset(&a, 0, sizeof(a));
  a.sin_family = AF_INET;
  a.sin_port = htons(static_cast<uint16_t>(port));
  if (::inet_pton(AF_INET, host.c_str(), &a.sin_addr) != 1) die("inet_pton");
  if (::connect(fd, reinterpret_cast<sockaddr*>(&a), sizeof(a)) != 0) die("connect");

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
      auto er = make_ret("?", "error", "{\"kind\":\"error\",\"message\":\"bad envelope\"}");
      uint32_t L = static_cast<uint32_t>(er.size());
      if (!send_all(fd, &L, 4) || !send_all(fd, er.data(), er.size())) break;
      continue;
    }

    if (fields["type"] != "REQ") continue;

    std::string call_id = fields["call_id"];
    std::string sid = fields.count("session_id") ? fields["session_id"] : "default";
    std::string code = fields.count("payload") ? fields["payload"] : "";

    try {
      Rcpp::Environment env = session_env(g, sid);
      std::string j = eval_code_json(code, env);
      bool ok = j.find("\"kind\":\"error\"") == std::string::npos;
      auto ret = make_ret(call_id, ok ? "success" : "error", j);
      uint32_t L = static_cast<uint32_t>(ret.size());
      if (!send_all(fd, &L, 4) || !send_all(fd, ret.data(), ret.size())) break;
    } catch (...) {
      auto ret = make_ret(call_id, "error", "{\"kind\":\"error\",\"message\":\"cpp/r error\"}");
      uint32_t L = static_cast<uint32_t>(ret.size());
      if (!send_all(fd, &L, 4) || !send_all(fd, ret.data(), ret.size())) break;
    }
  }
  ::close(fd);
}
