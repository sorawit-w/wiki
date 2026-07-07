## PR workflow (default for all repos; a repo's own CLAUDE.md overrides)

When opening a PR (base = the repo's default branch):

1. **Review before the PR.** If local Codex (`/codex:review`) is available, run it
   against the branch diff (`--base <default-branch> --scope branch`) and loop
   review → fix → re-review per the **Review loop (bounded)** rule below. Note `/codex:review`
   is user-only (`disable-model-invocation`) — the agent runs the same engine headless
   instead: `node <codex-plugin>/scripts/codex-companion.mjs review "--wait --base
   <default-branch> --scope branch"` via background Bash with an explicit timeout
   (verified working, piggy-hero PR #3; default timeout SIGTERMs), or substitutes
   `/codex:rescue` with a review brief; it also offers the review gate (see
   **Invocation caveat** under Plan review). "Not in my Skill list" is NOT "no local
   Codex" — that fallback is for when the plugin genuinely isn't installed.
   **Review loop (bounded).** Every review brief must carry the severity rubric and
   the verdict contract: "Tag each finding P0 (security / data-loss / correctness
   blocker), P1 (likely bug or broken contract), P2 (should-fix), P3 (nit). End the
   review with one final line: `CODEX_VERDICT: P0=<n> P1=<n> P2=<n> P3=<n>`, counting
   OPEN findings." If the invocation path can't carry a custom brief, use the
   rescue-with-brief substitute. Only open P0/P1 block: fix them, then run a SCOPED
   re-review ("verify these fixes + scan the fix diff" — never a fresh full-branch
   pass). P2/P3: fix in the same pass if trivial, otherwise log (issue or
   ponytail-debt) — they never trigger a re-review. Hard cap: 3 rounds —
   `codex-mark.sh` (below) counts rounds per branch and enforces it. Cap hit with
   open P0/P1 → HELD: stop, escalate to the user, no merge, no marker. Severity is
   Codex's call; Claude may downgrade a finding only with a one-line reason recorded
   in the PR body. "Clean review" throughout this section means: no open P0/P1
   within the cap.
   **PR gate (mechanical):** a global PreToolUse hook (`~/.claude/hooks/codex-pr-gate.sh`)
   blocks `gh pr create` unless a marker records a clean Codex review of the current
   HEAD. The marker is written ONLY by `~/.claude/hooks/codex-mark.sh` — never by
   hand; hand-writing it is gate-dodging. Tee every review's output to
   `$(git rev-parse --git-dir)/codex-review.log`, then run `~/.claude/hooks/codex-mark.sh`:
   it verifies a clean `CODEX_VERDICT` (P0=0 P1=0) against a log newer than HEAD,
   enforces the round cap (PASS / DENIED / HELD), writes the marker, appends to the
   audit log, and prints the PR-note line used in step 3. Any new commit stales the
   marker (re-review, re-mark). Deliberate bypass (user-approved only):
   include `CODEX_GATE_BYPASS=1` in the command. The gate verifies the repo at the
   session cwd, so run `gh pr create` as a standalone command — combining it with
   `cd`/`pushd`/`-C` is refused (would check the wrong repo). Known ceiling: the gate
   string-matches, so any Bash command containing "gh pr create" is checked. The **final** review must
   run against the exact tree you push — fix churn on the branch is throwaway (the
   squash-merge collapses it), but nothing may change after that last clean review.
2. **Open the PR**, then merge with `--squash --delete-branch` (squash keeps one commit
   per PR; `--delete-branch` because a repo may have `deleteBranchOnMerge` off).
3. **Local Codex clean → merge immediately**, pasting the PR-note line printed by
   `codex-mark.sh` into the PR body: `Codex-reviewed locally at <sha> · rounds=<n> ·
   P0/P1=0 · P2/P3 logged=<n>` — `<sha>` is the branch HEAD you reviewed and pushed.
   (Squash-merge changes the commit SHA on the default branch but not the content,
   so the note stays verifiable as "reviewed tree == PR head tree".)
4. **Fallback — no local Codex available** (plugin/CLI genuinely missing or broken,
   NOT merely absent from the Skill list): the mechanical PR gate will still block
   `gh pr create` with no marker — this is the one sanctioned marker-less use of
   `CODEX_GATE_BYPASS=1`, because the GitHub-side review below replaces the local one;
   never bypass when local Codex works. Open the PR (with the bypass), trigger a
   GitHub-side `@codex review` (include the P0–P3 rubric in the mention comment),
   and poll. **Address every P0/P1 comment before merging** — fix it
   (a fix is a new push → new review cycle) or push back with reasoning. P2/P3 comments
   get a reply plus a log entry (issue or ponytail-debt) and count as addressed. Never
   merge with an open, unaddressed P0/P1. Merge only on a green light **against the
   current head**: an approval / 👍 reaction dated after the latest push, or — once all
   comments are addressed — the silence cap after ≥1 completed review of HEAD (never when
   Codex never reviewed HEAD at all). **Cadence:** poll ~every **150 s**; if Codex isn't
   reviewing by the first poll, re-mention `@codex review`; each reply that addresses a
   comment resets the timer; merge at the silence cap — the **4th poll, ~10 min** after
   that reply. A clean signal (👍, or a completed no-findings review of HEAD)
   short-circuits the cap and merges immediately. Reaction pagination, the on-behalf
   disclosure, and the finer poll behaviors are in memory.

Enforcement note: the review-before-PR half IS mechanically gated (the PR gate in
step 1, global), and the clean-verdict attestation is now mechanical too
(`codex-mark.sh` — ceiling: it trusts the teed log; forging one is possible but
deliberate, and `$GIT_DIR/codex-review-audit.log` keeps the history visible). The
merge rules (steps 2–4) remain instruction only — they shape behavior but don't
block a bad merge; a repo wanting a hard merge gate needs its own hook.

## Plan review (default for all work; a repo's own CLAUDE.md overrides)

When drafting an implementation plan in Plan mode on a task, if the Codex plugin
is available (the `/codex` skill is present) **and the plan grades complex or
high-stakes** — under kerby's complexity grade when loaded; otherwise: irreversible
ops, money, security surface, multi-repo, or >~5 files — run
`/codex:adversarial-review` on the draft plan before presenting the final plan.
Simple plans skip the adversarial pass silently. Triage each finding: accept it
(revise the plan) or reject it with reasoning — Codex advises, Claude decides (same
lead-not-reviewer-follower stance as the PR workflow). One pass, no loop-until-Codex-
approves: Codex sign-off is not the termination condition; Claude's judgment is. All
findings must be resolved before the plan is presented, but resolved ≠ hidden — any
material finding that was rejected gets one line in the presented plan (what Codex
flagged, why it was rejected) so the user sees the dissent at approval time. Skip
silently when the plugin isn't installed.

**Invocation caveat:** `/codex:review` AND `/codex:adversarial-review` are user-only
commands (`disable-model-invocation` — 6 of the 8 codex commands are; only `rescue`
and `setup` are model-invocable), so they do NOT appear in the agent's Skill list and
the agent cannot self-trigger them — in an autonomous/unattended run, substitute
`/codex:rescue --background` with a review / adversarial-review brief (Codex advises,
Claude decides — same stance); a human can run the named commands directly.
**Whenever this caveat bites** (the agent wants `/codex:review` or
`/codex:adversarial-review` but can't self-invoke), it must also **offer the user
`/codex:setup --enable-review-gate`** — the plugin's built-in Stop-hook gate that runs
the review mechanically at stop-time, removing the agent from the loop entirely. Offer
once per repo per session, not on every occurrence; enabling is the user's call. General
rule: before asserting a `/codex` (or any plugin) capability is "not installed,"
verify on disk (`find …/commands -name '*.md'`) — the session skill list omits
`disable-model-invocation` commands, so absence-from-the-list ≠ not-installed.

**Cross-model role diversity (when to double up):** the default is a division of
labor, not two panels — Claude runs `team-composer` for role breadth; the Codex
model line is spent on *grounding* (the adversarial-review above, verifying against
code/specs), which is where a second model actually pays. Only for **greenfield /
divergent** planning — no spec or code to verify against — also run an independent
Codex role-lens pass: hand it the 2–3 seats most likely to disagree (e.g. skeptical
architect, security, domain expert) and have it argue *against* the draft; Claude
adjudicates (Codex advises, Claude decides). Do NOT default to a second full
`team-composer` panel on Codex — the same roles on a different engine buy a second
narrative, not diverse grounding, at ~2× planning cost. Non-negotiable whichever
path: the trust-bearing step is a second model checking the artifact, never the
models discussing more.

## Codex delegation (when the `/codex` plugin is present)

When stuck — a retry budget exhausts, a debugging hypothesis cap hits, or two
consecutive fix attempts fail the same way — run `/codex:rescue` for an independent
diagnosis pass before escalating to the user. Prefer `--background` for open-ended
investigations (use `--effort high` for deep root-cause work) and keep working
meanwhile; check with `/codex:status` and fetch with `/codex:result`. Codex advises;
Claude decides — its diagnosis is a hypothesis to verify, not a fix to apply blind.
This is a rung before human escalation, not a replacement for it: if the independent
pass doesn't break the deadlock, escalate as usual. The stop-time review gate
(`/codex:setup --enable-review-gate`) stays off by default — enable per-repo only if
the prose review workflows are observed being skipped. Cost caveat (state it when
offering the gate): the Stop hook spawns a Codex task on **every** turn end — the
"skip non-edit turns" logic is inside the Codex prompt (instant ALLOW), not the hook —
so even chat-only turns pay one Codex round trip; 15-min timeout. Good for build-heavy
repos that ship PRs, wasteful for mostly-conversational sessions.
