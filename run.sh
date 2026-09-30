#!/bin/sh
# The polyformalism canary, Futhark and BQN.
#   ./run.sh          run whatever is available
# Futhark is verified. BQN is expected to be BLOCKED -- see BQN-FINDINGS.md for the nine
# blockers, eight of which produce a plausible wrong number rather than an error.
set -e
PATH=/opt/langs:$PATH
TARGET_HEX=24a555471370b18d
TARGET_DEC=2640610520279855501

echo "canary target: 0x$TARGET_HEX = $TARGET_DEC"
echo

echo "--- Futhark 0.27.1 ---"
if [ -x canary-futhark ]; then
  R=$(./canary-futhark | sed 's/u64$//')
  echo "  fnv1a64(\"café Δ 日本語\") = $R"
  [ "$R" = "$TARGET_DEC" ] && echo "  MATCH" || echo "  MISMATCH"
else
  futhark c canary.fut -o canary-futhark && echo "  (compiled)"
fi
echo

echo "--- BQN (via its own JS build on node) ---"
node /opt/langs/bqn-src/bqn.js < /dev/null 2>/dev/null && echo "  interpreter present" || true
printf '0\n' > /tmp/bqn_run
cat canary.bqn >> /tmp/bqn_run
printf '\n•Show canary\n•Show check\n' >> /tmp/bqn_run
OUT=$(node /opt/langs/bqn-src/bqn.js < /tmp/bqn_run 2>&1) && echo "  $OUT" || echo "  BLOCKED -- see BQN-FINDINGS.md"
