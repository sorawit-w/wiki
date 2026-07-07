#!/bin/sh
# PreToolUse gate (matcher: Bash): block `gh pr create` unless a Codex review
# marker exists for the current HEAD. Marker is written after a clean review:
#   git rev-parse HEAD > "$(git rev-parse --git-dir)/codex-reviewed"
# Bypass deliberately: include CODEX_GATE_BYPASS=1 in the command.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
else
  cmd=$input  # ponytail: no jq -> match whole payload; rare false positive, bypass hatch covers it
fi

case "$cmd" in
  *"gh pr create"*) ;;
  *) exit 0 ;;
esac

case "$cmd" in
  *CODEX_GATE_BYPASS=1*) exit 0 ;;
esac

# The marker check below runs in the hook's cwd. A command that changes
# directory first would be checked against the WRONG repo, so refuse it.
case "$cmd" in
  *"cd "*|*"pushd "*|*" -C "*)
    echo "Codex PR gate: run 'gh pr create' as a standalone command from the session's working directory — combining it with cd/pushd/-C would make the gate check the wrong repo. To bypass deliberately, include CODEX_GATE_BYPASS=1." >&2
    exit 2 ;;
esac

gitdir=$(git rev-parse --git-dir 2>/dev/null) || exit 0
head=$(git rev-parse HEAD 2>/dev/null) || exit 0

marker="$gitdir/codex-reviewed"
if [ -f "$marker" ] && [ "$(cat "$marker")" = "$head" ]; then
  exit 0
fi

echo "Codex PR gate: no clean Codex review recorded for HEAD ($head)." >&2
echo "Run the local Codex review (/codex:rescue with a review brief, or the user runs /codex:review), fix findings, then record it:" >&2
echo "  git rev-parse HEAD > \"$gitdir/codex-reviewed\"" >&2
echo "Only record after a clean review of this exact tree. To bypass deliberately, include CODEX_GATE_BYPASS=1 in the command." >&2
exit 2
