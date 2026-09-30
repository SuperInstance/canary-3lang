-- The fleet canary in Futhark.
--
-- FNV-1a 64 over the UTF-8 bytes of "café Δ 日本語" — 18 bytes, written out below.
-- They are literal in the source rather than read from a file, so nothing about character
-- encoding, locale, or argument parsing is an input to the test. Anything that can produce
-- these 18 integers has enough information to check this port.
--
-- Three things this port had to discover, each by failing first:
--
--   1. Futhark has no integer XOR builtin. It is expressed through the algebra as
--      (a|b) - (a&b), which is exact for two's complement.
--   2. Futhark performs no implicit numeric promotion: u8 will not widen to u64, not even
--      by adding a u64-typed literal. So the byte array is [18]u64 from the start.
--   3. Application binds tighter than *, so a conversion inside a product needs its own
--      parentheses. Written flat it becomes b*prime and the hash is simply wrong, silently.
--
-- u64 arithmetic wraps, which is the required FNV-1a semantics. An i64 port would overflow
-- negative and return a wrong number with no error at all. That is why the type is u64 and
-- not i64, and why the assertion below is on the exact u64 value.

def BYTES : [18]u64 =
  [ 99, 97, 102, 195, 169, 32, 206, 148, 32,
    230, 151, 165, 230, 156, 172, 232, 170, 158 ]

def xor64 (a: u64) (b: u64) : u64 = (a | b) - (a & b)

def fnv1a64 [n] (bs: [n]u64) : u64 =
  let init  = 0xcbf29ce484222325
  let prime = 0x100000001b3
  let step (h: u64) (b: u64) : u64 = xor64 h b * prime
  in foldl step init bs

-- Known-answer control.
--
-- This control is the reason the port's one real bug was caught. The implementation was
-- correct throughout. What was wrong was a DECIMAL copy of the expected value pasted into
-- a shell comparison: 0x024a555471370b18d is 2640610520279855501, not
-- 16314074854619246109. A hardcoded constant nobody can re-derive is a test that lies.
--
-- Two further things worth keeping:
--   - the é carries an accent. "café Δ 日本語" hashes to the canary; "cafe Δ 日本語"
--     does not. A transliterated fixture silently tests a different thing.
--   - this constant is in hex precisely so it can be checked against the other ports
--     by eye, without a base conversion in between.
def check : i32 =
  if fnv1a64 BYTES == 0x024a555471370b18d then 1 else 0

def main : u64 = fnv1a64 BYTES

-- The control, runnable: prints 1 when the canary reproduces.
def verify : i32 = check
