# Roadmap: Ruby ↔ R communication via Apache Arrow

Status: **B1 implemented** (Stage C still future)  
Audience: Galaaz maintainers  
Related: [Specification.txt](Specification.txt) (older “RAM-disk / Shadow Vector” sketch — **superseded for transport** by this roadmap + `Galaaz::ArrowIpc`),  
ledger demo honesty notes in `r_on_rails_ledger/docs/architecture.md`

---

## Recommendation (short answer)

**Yes: do B first, then C.**

| Stage | Name | Goal |
|-------|------|------|
| **A** | Today | Bridge copy → R-side Arrow + proxies (`from_ruby_batches` / `table_from`) |
| **B** | IPC / mmap file handoff | Ruby writes Arrow IPC; R opens by path; only the path crosses NewBridge |
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

Ruby materializes an **Arrow IPC** payload in a file that R can **memory-map**. NewBridge carries only the path. Analytics stay on R proxies.

### B1 status (shipped)

```ruby
path = Galaaz::ArrowIpc.write(value: doubles, id: ints, grp: strings)
tbl  = R::Arrow.open_ipc(path)   # Arrow Table proxy; materializes in R
Galaaz::ArrowIpc.release(path)   # unlink after open (default lifetime)
```

| Topic | Choice |
|-------|--------|
| Direction | Ruby → R ingest only |
| Format | Arrow IPC **file** (`arrow::read_ipc_file(..., as_data_frame=FALSE)`) |
| Scratch | Prefer `/dev/shm`; else `Dir.tmpdir/galaaz_arrow_ipc` |
| Lifetime | Copy-into-R then unlink (safe after `open_ipc` returns) |
| `from_ruby_batches` | Unchanged; separate Stage A API |
| Writers | **Dual:** CRuby → **red-arrow** (`gem install red-arrow`); JRuby → **Apache Arrow Java** |

**Writers (honesty):** both backends produce a file. JRuby’s Java stack can write concurrent distinct files without the MRI GVL; that is **not** zero-copy into R’s heap.

**Install notes**

- R: `install.packages("arrow")` (and `dplyr` for typical analytics).
- CRuby: `gem install red-arrow` (needs system Arrow/GLib/gobject-introspection packages). Do **not** install the unrelated legacy Rubygems package named `arrow`.
- JRuby: set `GALAAZ_ARROW_JARS` to a directory of Arrow Java JARs (e.g. 18.1.0), or place them in `~/arrow_jars`, or resolve via `jar-dependencies`. Keep `-J--add-opens=java.base/java.nio=ALL-UNNAMED`.

**Tests:** `specs/arrow_ipc_handoff_spec.rb`, `new_bridge_specs/arrow_ipc_async_spec.rb` (skip when writer or R `arrow` missing).

### Out of scope for B1 (still)

- Bidirectional R → Ruby bulk export (B2).
- Docker bind-mount path translation (B3).
- Mutating the same buffer from both languages concurrently.
- Stage C shm bus.

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
A (done) ──► B1 Ruby→R IPC/mmap on same host (done)
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
| Ruby writer? | **red-arrow** (CRuby) + **Arrow Java** (JRuby). |
| IPC file vs stream? | **File** format for B1. |
| Lifetime? | **Copy-into-R then unlink** after `open_ipc`. |
| `from_ruby_batches` → B? | **No** for now — separate APIs. |
| `Specification.txt`? | **Superseded** for transport; keep as historical sketch. |

---

## Honesty checklist (docs & pitches)

**Say**

- Ingest via Arrow IPC / mmap file; analytics via proxies in R.
- Same-machine first; path (or shm name) crosses the bridge.

**Do not say until C ships and is measured**

- “Ruby and R share one physical Arrow table with 0 ms transfer.”
- “Drop-in replacement for GraalVM FastR shared heap.”

---

## History

| Date | Note |
|------|------|
| 2026-09-03 | Roadmap created: A/B/C stages; recommend B→C; B helps C but is not C. |
| 2026-09-03 | B1 shipped: `Galaaz::ArrowIpc` dual writers + `R::Arrow.open_ipc`; sync/async specs. |
