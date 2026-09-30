# Substrate constraints — Futhark 0.27.1 and BQN

Everything here was found by execution. The manual does not state most of it.

## Futhark 0.27.1

1. **There is no elementwise arithmetic on 2-D arrays.** `a + b` on `[n][m]f64` is a type
   error: `Expected: [][]f64. Actual: [][]f64` — the types print identically and are not
   the same type. `map` and `map2` on 2-D are **row-wise**, so `map2 (+) a b` fails too.
   Use a nested map or `map2 (\ra rb -> map2 (+) ra rb) a b`. This is the first hour you
   will lose.
2. A gather and an arithmetic op cannot share a lambda. The gather alone is fine.
3. Size parameters `[n][d]` are entry-point-only. On an internal `def`: "Unknown name".
4. Reserved words: `type`, `entry`, `entrypoint`. The entry point is `def main`.
5. No implicit numeric promotion — not even by adding a wider-typed literal. No integer
   XOR; it is `(a|b) - (a&b)`. `^^` is *boolean* xor.
6. Shape inference does not flow reliably through let-bound multi-dimensional
   intermediates. Annotate or it will not unify.
7. **Arrays are regular, not ragged.** A jagged value is not an array in this language. CSR
   is flat values + offsets, and dynamic-bound slicing is what makes it legal.
8. `--memory-limit` is a runtime allocation limit, not out-of-core paging.
9. Out-of-bounds indexing and integer wraparound have **no portable diagnostic** — wrong
   results or crashes are possible, per the manual.
10. Failure to fuse is not proof of impossibility. Use
    `futhark dev --kernel-history=...` and `futhark inspect` before concluding anything.
11. `u64` wraps natively, which is exactly what FNV-1a wants. This is Futhark's single
    biggest advantage over BQN.

## BQN

Hard constraint first: **a 64-bit value is unrepresentable.** Scalars are JS doubles, exact
to 2⋆53. The canary is 2640610520279855501, far past that. It can be *computed* in 16-bit
limbs and cannot be *named*.

1. **No hex literals.** `0x1f` is rejected: "Letters xf not allowed in numbers". A trailing
   comment on a hex line gets absorbed into the digits.
2. Any name starting uppercase is a function/modifier role. `BYTES ← …` is a role error.
3. `n | x` is mod with the divisor on the **left**. `32 | 55` is 23.
4. `÷` does not floor.
5. `a[0]` is not indexing. `⊑a` and `1 ⊑ a` are.
6. No `&`/`|`; they are `∧`/`∨`. No xor: `(a ∨ b) - (a ∧ b)`.
7. A file may not begin with a comment when read through stdin — silence, no error.
8. Single quotes are character literals; strings are `"..."`.
9. **No 2-argument function application.** `Add 3 4`, `f g 5`, `{𝕨 F 𝕩}` all raise
   "Double subjects". Seeding a left fold has no direct syntax. **This is where the port
   stopped** — the limb arithmetic is solvable, the fold ergonomics are not.

**Eight of the nine return a plausible wrong number rather than an error.** That is the
cost of porting into it and the reason the findings are written down.
