# canary-3lang

The fleet's polyformalism canary — FNV-1a 64 over the UTF-8 bytes of `café Δ 日本語` —
in Futhark, BQN, and (pending) Uiua.

```
target: 0x24a555471370b18d = 2640610520279855501
```

## Status

| substrate | state | note |
|---|---|---|
| **Futhark 0.27.1** | **VERIFIED** | reproduces the canary exactly |
| **BQN** | blocked | nine documented blockers, eight of which return a plausible wrong number |
| **Uiua** | in progress | toolchain installed, source build in flight |

Run `./run.sh` to reproduce the Futhark result.

## What the ports are for

This is not a language test. Every substrate in the fleet carries the same canary, and the
canary is how you know a substrate did not change while you were not looking. A port that
returns a plausible wrong number is worse than a port that refuses to compile.

## Two things worth knowing before you touch the fixtures

**The accent is load-bearing.** `café Δ 日本語` hashes to the canary. `cafe Δ 日本語` does
not. A transliterated fixture silently tests a different thing.

**Put the expected value in hex, not decimal.** The failure mode in this repo's own
history: a mistyped decimal for a hex digest made a correct port look broken. A second
one: `tr -d 'u64'` to strip Futhark's type suffix deleted the `6` and the `4` out of the
number itself. Both errors were in the *check*, not the code. The check is where the
errors live.

See `THREE-SUBSTRATES.md` for why these three languages specifically, and
`BQN-FINDINGS.md` for the blocked port.
