# Uiua, Futhark, BQN — the parts that mattered, and where each one is actually load-bearing

Status: **Futhark 0.27.1 verified** (canary reproduced). BQN blocked, nine documented
blockers in `BQN-FINDINGS.md`. Uiua compiling from source.

The framing is not "port more things." It is: *each of these three languages has exactly
one property the other two lack, and each property maps onto a problem the fleet has been
carrying in Python because it had no better tool.*

---

## Futhark — locality is a primitive

**What only Futhark has:** `˘`, windows, halos. Neighbourhoods are language constructs, not
loops you write. BQN and Uiua are both whole-array languages; neither gives you locality
for free.

**Narrow and certain:**
- The aperture experiment. Content matching over a cell grid is a windowed comparison. The
  33.2%→100% miss-rate finding was a per-cell loop; in Futhark it is one windowed `map`
  with a halo. Real, measurable, and it is *the* experiment that motivated the motion-vector
  work in the first place.
- The ledger. Per-namespace per-cell balance is a fold plus a broadcast comparison. 10⁶
  cells is uninteresting on a GPU and miserable in Python.
- The witness chain. The FNV-1a port already exists; as a scan over cell bytes it is
  trivially parallel across cells.

**The bet worth making:** **TICK as one kernel over the whole quilt.** If a cell's tick
depends only on its neighbourhood — and it does, the dial movement is graph-local — then
the entire graph is one array operation. Today it is N method calls. The win is not
constant-factor; it is that the *fleet's central architectural claim* becomes a single
falsifiable statement: "the quilt ticks in one call." Either that is true and it is
enormous, or it is false and we learn where locality actually breaks. Both outcomes are
worth more than the port.

**What it costs:** no algebraic types, no dynamic dispatch, no text. The 11-opcode algebra
becomes an integer tag plus a `match`. Acceptable — the cell kind is already an enum.

---

## Uiua — the interpreter is a program in the language

**What only Uiua has:** instructions are ordinary data, and the interpreter is written in
the same language it interprets. Plus a real linear-memory flat array and C interop.

**Narrow and certain:**
- The wheel's sequential spine with parallel angles. `spawn`, `&`, and I/O make a real DAG
  scheduler natural rather than a subprocess mess.
- The recipe-v5 fallback. "Run the pool driver, kill after 75s, otherwise use the
  hand-written piece" is not a workaround to work around — it is a control-flow shape Uiua
  expresses directly. That pattern has been re-derived by hand for fourteen consecutive
  sessions.
- The 11-opcode algebra as a small interpreter. Tagged dispatch in Uiua is a pleasure, and
  the opcode set is small enough that the interpreter is shorter than its own tests.

**The bet worth making:** **a cell that carries its own evaluator.** Because instructions
are data, a cell could store the *program that evaluates it* as its content. The cell stops
being a data structure plus an interpreter and becomes a program that is also its own
witness — the witness log is then not a log of what happened to the cell, it is the cell.
This is the most original idea in this document and also the least proven. Sketch, not
result.

---

## BQN — implicit arguments are free, so provenance is structural

**What only BQN has:** `𝕨` and `𝕩` are always in scope, and combinators are first-class.
A tacit program *is* a combinator tree.

**Narrow and certain:**
- The 11-opcode algebra. A tacit interpreter is compact and tag dispatch is a merge/sort.
  This is the most immediately useful of the three.
- **Provenance in the witness log.** In BQN, "who called me" is not a parameter you thread
  through the evaluator — it is already in scope. The fleet's witness problem is precisely
  that provenance has to be *carried*, and BQN makes it ambient. Of the three ideas here
  this is the most likely to actually work, because it is structural rather than a feature
  you would have to add.
- Short verifiers. A whole FNV-1a is about ten BQN lines. When the implementation is
  smaller than its test, inspection becomes a real verification method — and smallness is
  the actual bottleneck on the fleet's polyformalism claim. Not "can we port 24 repos" but
  "can we make each port small enough to check by eye."

**What it costs:** `2⋆53` scalars mean a 64-bit value is unrepresentable, and nine separate
ergonomic traps produce plausible wrong numbers rather than errors. Documented, not
surmounted.

---

## The cross-cutting reading

| language | unique property | fleet problem it fits |
|---|---|---|
| Futhark | locality as a primitive | TICK: one kernel, not N cell calls |
| Uiua | code is data, interpreter in-language | cells that carry their own evaluator |
| BQN | implicit arguments are free | provenance in the witness log, unthreaded |

None of these are three ports. They are three capabilities the fleet currently simulates
in Python because Python cannot express them.

## Order, and why

1. **BQN on the 11-opcode algebra.** Smallest, most likely to land, and the provenance
   result is the one that could change how the witness log is built rather than just
   where it runs.
2. **Futhark on TICK.** The benchmark is the whole experiment: per-cell loop versus one
   kernel, on a real graph, with the fleet's own locality claim as the hypothesis.
3. **Uiua self-evaluating cell.** Sketch before code. It is the most interesting idea and
   the one most likely to collapse on contact, which is fine, because that is what
   sketches are for.

## The honest risk

Everything above is a hypothesis about *capability*, not a measurement. Futhark can be
benchmarked this week and should be. The Uiua idea has no known failure mode yet, which
usually means the failure mode is unknown. BQN's blockers are real and documented, and
nobody should spend more on it until the fold-seeding question is answered.
