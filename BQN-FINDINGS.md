# BQN findings — canary NOT reproduced, blockers named

Futhark 0.27.1 **reproduces** the canary. BQN does not, and the reasons are worth more
than a forced success would be. Every item below was hit in practice, and every one of them
produces a **plausible wrong number rather than an error** — which is the dangerous class.

## Hard constraint: a 64-bit value is unrepresentable

BQN's scalars are JS doubles, exact to `2⋆53`. `0x24a555471370b18d` is 2640610520279855501,
far past 2⋆53. Writing it as a literal silently rounds it, and every comparison after that
is against a number that never existed. A 64-bit hash can be *computed* in limbs, but
cannot be *named*. That is a real architectural difference from Futhark, where `u64` wraps
natively and the whole thing is one expression.

## The blockers, in the order they surfaced

1. **No hex literals.** `0x1f` is rejected: *"Letters xf not allowed in numbers."* Every
   constant must be decimal. Worse, a trailing comment on a line with a hex literal gets
   absorbed into the digits — `0xcbf29ce4          # comment` parses as one malformed number.
2. **Any name starting uppercase is a function or modifier.** `BYTES ← 63 ‿ 61` is a
   *role* error, not a binding error. Nouns are lowercase. `B` is specifically a 1-modifier.
3. **`n | x` is mod with the divisor on the LEFT.** `32 | 55` is 23. Backwards from every
   other substrate the fleet ports to, and reading it the usual way is silently wrong.
4. **`÷` does not floor.** `n ÷ base⋆3` returns `1.5e¯5` where the limb is `0`. Needs `⌊`.
   This is the one that produced a visible `∞` further down the pipeline.
5. **`a[0]` is not indexing.** `⊑a` and `1 ⊑ a` index a pair; `a[0]` is read as a modifier
   application and answers *"Double subjects (missing ‿?)"*.
6. **No bitwise `&`/`|`.** The names are `∧` and `∨`; `|` is mod. There is no xor, so it is
   built from the algebra as `(a ∨ b) - (a ∧ b)` — the same two lines Futhark needs, which
   is the one thing the two ports share outright.
7. **A file may not begin with a comment.** `#` is a valid comment, but only after code has
   started; a comment-first file read through stdin produces silence and no error. `"f.bqn"
   Load file` also failed to splice definitions in this build. Runner prepends a `0`.
8. **Single quotes are character literals.** `'f.bqn' Load file` is *"Unclosed quote"*;
   strings are `"f.bqn"`.
9. **No 2-argument function application.** `Add 3 4`, `f g 5`, and `{𝕨 F 𝕩}` all raise
   *"Double subjects (missing ‿?)"*. A 2-argument "function" must be a 2-train, and seeding
   a left fold has no direct syntax. This is where the port stopped: the arithmetic is
   solvable, the ergonomics of threading `(acc, element)` through a fold are not, within a
   reasonable budget.

## What is nonetheless settled

The limb arithmetic is written and correct in shape: 16-bit limbs (32-bit limbs overflow the
53-bit exact range), schoolbook multiply truncated to the low four limbs, carry propagated
by hand. A seeded fold is the only missing piece. The blockers are in the *interface*, not
in the algorithm — which is a different and more fixable problem than a missing algorithm.

## The lesson, which is the same one as always

Nine blockers, and **eight of them returned a plausible value instead of an error**. A
language that fails loudly is cheap to port. One that fails quietly is expensive, and the
expense is paid in exactly the place this fleet has been bleeding: the check, not the code.
