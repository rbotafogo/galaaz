# Roadmap: Ruby ↔ R communication via Apache Arrow

Status: planning (no implementation commitment in this file)  
Audience: Galaaz maintainers  
Related: [Specification.txt](Specification.txt) (older “RAM-disk / Shadow Vector” sketch),  
ledger demo honesty notes in `r_on_rails_ledger/docs/architecture.md`

---

## Recommendation (short answer)

**Yes: do B first, then C.**

| Stage | Name | Goal |
|-------|------|------|
| **A** | Today | Bridge copy → R-side Arrow + proxies (`from_ruby_batches` / `table_from`) |
| **B** | IPC / mmap file handoff | Ruby writes Arrow IPC (preferably. mmap); R opens by path; only the path crosses NewBridge |
| **C** | Shared-memory bus | Both processes attach to one live segment; streaming / reuse without a “file per transfer” |

**Does B help with C?** Yes, substantially — but B does **not** become C automatically.

B forces the hard *product* decisions that C needs: Arrow schema contracts, endianness, lifetime,
who owns the buffer, version pins (`arrow` on R vs Ruby writer), one-way ingest vs bidirectional,
and “path/handle over the bridge, bytes not over MsgPack.” C then swaps the **transport**
(file/`mmap` path → POSIX shm / memfd / Arrow Plasma-style segment) while reusing the same
**format and API shape**.

Skipping B and jumping to C usually means debugging shared-memory bugs *and* format/API bugs at once.

---

## What is true today (Stage A)

- GNU R runs in a **separate process** (NewBridge). Ruby does **not** hold an Arrow C++ table.
- `R::Arrow.from_ruby_batches` / `table_from` **copy** columnar data into R, then return an
  `R::Object` **proxy** (bridge handle).
- After ingest, the right model is **Remote Control**: move commands (`R.quantile`, dplyr, …),
  keep panels in R, **opt-in unbox** for KPIs.
- Docker / second host: even harder; same-machine B is the natural first win.

**Do not claim for A:** “zero-copy shared RAM,” “transfer is 0 ms,” “Ruby and R map the same bytes.”

---

## Stage B — Same-machine Arrow IPC / memory-mapped file

### Intent

Ruby (or a small native helper) materializes an **Arrow IPC** (or Feather) payload in a file that
can be **memory-mapped**. NewBridge carries only:

```text
{ op: "open_ipc", path: "/dev/shm/galaaz_….arrow" }   # or under a dedicated scratch dir
```

R runs something equivalent to mapping/opening that file via the `arrow` package and returns a
proxy to the R-side table/dataset.

### Why this is the right next step

- Same machine (dev laptop, CI, local Rails + local R): **no container IPC namespace** required.
- Avoids stuffing large vectors through MsgPack.
- Aligns with industry practice (Arrow IPC files / mmap readers).
- `/dev/shm` or tmpfs gives “feels like RAM” without inventing a custom binary layout yet.
- API can look like:

  ```ruby
  path = Galaaz::ArrowIpc.write(batches)           # Ruby side
  tbl  = R::Arrow.open_ipc(path)                  # R maps; returns proxy
  # … R.* on tbl …
  Galaaz::ArrowIpc.release(path)                  # explicit lifetime
  ```

### Scope for a first milestone (B1)

1. **Direction:** Ruby → R ingest only (Rails/SQLite → risk engines).
2. **Format:** Arrow IPC file (streaming or file format — pick one and stick to it).
3. **Location:** prefer `/dev/shm` on Linux when available; fallback to gem `tmp/`.
4. **Bridge:** one new thin opcode or `R::Arrow.open_ipc(path)` implemented as a short R eval
   that uses `arrow::…` mmap/open APIs.
5. **Lifetime:** writer creates; reader opens; **Ruby unlinks** after R has a stable in-R copy
   *or* after an explicit `release` once R is done (document the chosen rule).
6. **Tests:** round-trip float64 column; multi-column frame; large-ish N (e.g. 1e6) vs
   `from_ruby_batches` wall time; failure if `arrow` missing in R.
7. **Docs:** honest wording — “mmap IPC handoff,” not “zero-copy shared heap.”

### Out of scope for B1

- Bidirectional R → Ruby bulk export (can be B2).
- Docker bind-mount path translation (B3 / ledger-specific).
- Mutating the same buffer from both languages concurrently.

### Effort (order of magnitude)

**Days to ~2 weeks** for a solid B1 if Arrow versions cooperate and the Ruby writer exists
(Ruby Arrow gem, or write IPC via a tiny C/Rust helper, or temporarily “Rscript writes from
scan” is *not* the goal — prefer a real Arrow writer on the Ruby side).

---

## Stage C — Shared-memory Arrow bus

### Intent

Both processes attach to a **named shared segment** (POSIX shm, memfd, or an Arrow-oriented
shared-memory service). No durable file path required for the hot path; the bridge passes a
**segment id / name + schema offset**.

### What B already gave you (reuse in C)

| From B | Reuse in C |
|--------|------------|
| Column types / schema contract | Same IPC schema inside the segment |
| “Handle over bridge, payload elsewhere” | Replace path with shm name |
| Lifetime / release protocol | Same state machine; different teardown |
| R `arrow` package expectations | Same reader APIs where possible |
| Benchmarks & honesty docs | Extend; don’t rewrite the story |
| Single-writer ingest path | First C mode = single writer (Ruby), single reader (R) |

### What B does *not* solve (new hard work in C)

- Segment create/attach/detach across process crash
- Concurrent writers / partial batch visibility
- Security (who can open `/dev/shm/galaaz_*`)
- Cross-platform (macOS shm vs Linux; Windows later)
- Interaction with R’s and Ruby’s GC / finalizers
- Optional: streaming RecordBatch ring buffer

### Effort (order of magnitude)

**Weeks+** after B is stable. Treat C as a **performance / scale** project, not a prerequisite
for the Remote Control DSL story.

---

## Suggested sequencing

```text
A (done) ──► B1 Ruby→R IPC/mmap on same host
              │
              ├──► B2 R→Ruby export (optional)
              ├──► B3 Docker path mapping (optional, ledger)
              │
              └──► C1 single-writer shm (same schema as B)
                     └──► C2 streaming / multi-batch (later)
```

**Parallel track (unchanged):** Remote Control proxies, opt-in unbox, multi-R via
`RInstanceManager` — these stay valuable whether transport is A, B, or C.

---

## Decision record

| Question | Answer |
|----------|--------|
| Start with B then C? | **Yes.** |
| Does B help C? | **Yes** — format, API, lifetime, and “bytes off the MsgPack bridge.” |
| Is B enough for most Rails demos? | **Often yes** — ingest once, then proxies. |
| When is C justified? | Repeated multi-GB handoffs, tight loops of re-ingest, or proven B bottleneck. |
| Same machine first? | **Yes.** Containers only after B1 works on host paths / `/dev/shm`. |

---

## Honesty checklist (docs & pitches)

**Say**

- Ingest via Arrow IPC / mmap file; analytics via proxies in R.
- Same-machine first; path (or shm name) crosses the bridge.

**Do not say until C ships and is measured**

- “Ruby and R share one physical Arrow table with 0 ms transfer.”
- “Drop-in replacement for GraalVM FastR shared heap.”

---

## Open questions (resolve before B1 coding)

1. Ruby Arrow writer: which library / minimum Ruby version?
2. IPC file format vs stream format?
3. Lifetime: copy-into-R-then-unlink vs keep mmap open for the session?
4. Should `from_ruby_batches` eventually call B under the hood, or remain a separate API?
5. How does this relate to the older `/dev/shm` notes in `Specification.txt` — merge, supersede,
   or archive?

---

## History

| Date | Note |
|------|------|
| 2026-09-03 | Roadmap created: A/B/C stages; recommend B→C; B helps C but is not C. |
