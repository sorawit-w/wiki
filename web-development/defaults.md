# Web Development Defaults

Agent conventions for web development work: default stack, default services, and skill routing.
Written for Claude Code / Cowork sessions, portable to any agent that reads instruction files.

---

## Scope & precedence

Applies to web development work — new projects, features, UI work, APIs — unless a more specific
instruction overrides it.

Priority order (highest wins):

1. The user's live instruction in the current session
2. Project-local config (`CLAUDE.md` / `AGENTS.md` / `DESIGN.md` / kerby rulebooks, when present)
3. This document
4. Individual skill defaults

---

## Skill availability rule (read this first)

Every skill named below is **conditional on being installed in the current environment**.

- Before invoking a skill, confirm it actually exists (skill list / plugin registry). Skill
  inventories drift between machines and sessions — never assume.
- If a relevant skill is missing: do the work directly with best judgment, and mention in one line
  which skill would have applied. Don't block, don't degrade the task, don't nag.
- Skills are accelerators, not dependencies.
- Route by fit, not by novelty. If no skill genuinely fits the task, use none.
- When two skills plausibly apply, pick **one** using the routing below — never stack overlapping
  skills on the same task.

---

## Default stack

**This document is the source of truth for stack defaults.** New projects follow the table below;
deviations require a named override factor (team expertise, compliance / data residency, ecosystem
constraint, cost at scale, realtime needs) stated out loud.

| Layer | Default |
|---|---|
| Runtime / package manager | Bun |
| Frontend | SvelteKit (Svelte 5). Exception: Astro when the project is a **simple marketing site and SEO is the priority** — content-first, little app logic. Anything app-like stays SvelteKit. |
| API | Elysia + Eden RPC (end-to-end types) |
| Database | Neon (serverless Postgres) |
| ORM | Drizzle |
| Auth | Clerk |
| Styling | Tailwind + plain CSS; shadcn only when a component library earns its place |
| Icons | Font Awesome, latest major version |
| Local dev database | Postgres in Docker (Compose); Neon is the preview/production target, not the local loop |
| Monorepo | Bun workspaces (`apps/`, `packages/`). Standard apps: `web`, `api` (usually needed), `admin` (only if needed). |

Rules:

- **Greenfield TS/JS project → this stack.** If deviating, name the override factor out loud —
  never silently swap a layer.
- **Existing repos: apply per piece.** Adopt the default for any layer the repo lacks; skip each
  piece where the repo already made a different choice. Don't propose migrations unprompted.
- **Scope rule:** scaffold only the layers the task needs. A CLI, script, or library does not get
  a database, auth, and UI shell by default.

---

## Default services

| Concern | Default | Notes |
|---|---|---|
| VCS / PRs | GitHub | Feature branches + PRs. |
| Hosting / deploy | Railway | |
| DNS | Cloudflare | |
| Object storage | Cloudflare R2 | Images and other user-facing assets. |
| Database | Neon (preview/production) | Serverless Postgres; DB branching for preview environments when useful. Local development runs Postgres in Docker (see stack table). |
| Auth | Clerk | Compliance/self-hosting requirements are a veto — swap to a self-hostable provider when they apply. |
| AI / LLM gateway | OpenRouter | Default for AI features; select models per task through it. |
| Product analytics | PostHog | Wire events intentionally; no analytics scaffolding on throwaway prototypes. |
| Payments | Stripe or PayPal, **only when the project actually needs payments** | Anything touching money flows: stop and confirm with the user before wiring it. |
| Error monitoring | Sentry, when connected | Don't add monitoring scaffolding to throwaway prototypes. |

Service hygiene:

- **Env convention:** one shared `.env` at the repo root for all workspace apps; `.env.local` for
  local-dev overrides (gitignored); `.env.example` committed with placeholder keys only.
- **License gate: AGPL dependencies are a hard block.** Check the license before adding any
  dependency; prefer MIT/Apache/BSD.

---

## Repo initialization

Every new repo gets this sequence after basic scaffolding (git + Bun workspace):

1. `kerby install swe` — installs the governance harness with the `swe` rulebook. After install,
   kerby still loads only on explicit invocation (hard rule 4 below).
2. `codex:setup` — wires up the Codex companion plugin for this repo.
3. `/impeccable init` — establishes impeccable's design workflow context, making it the incumbent
   (already-in-place) design system for the project.
4. Create the root env files per the env convention in Service hygiene, then stand up the Docker
   Compose Postgres service from the stack table and point `.env.local` at it.

`DESIGN.md` is **not** auto-generated at init — it comes from the user running
`agent-skills:brand-workshop` (see Design & UI below).

---

## Skill routing

### Hard rules

1. **One design-language skill per surface.** Never load `impeccable`, a `taste-skill:*` variant,
   and `ui-ux-pro-max` together on the same build — they are competing design systems and will
   fight each other.
2. **The project's `DESIGN.md` is canonical.** Design skills execute and refine within it; they
   never override its tokens, fonts, or rules.
3. **Prefer the incumbent** (the one already in use). Because `/impeccable init` runs at repo
   setup, the incumbent is impeccable unless the repo's artifacts say otherwise
   (`design-system/MASTER.md`, a taste-skill-styled codebase).
4. **kerby: installed at init, loaded on invocation only.** `kerby install swe` is part of repo
   setup, but load it only on explicit mention (`kerby`, `/kerby`, load/audit requests) — never
   auto-load it for general coding tasks.
5. **Don't restate kerby.** Implementation discipline (plan gate, test-first evidence, verdicts),
   secret scanning, `.env`-edit protection, protected branches, and destructive-git blocking all
   belong to kerby's `swe` rulebook and hooks. This document routes around them — it never
   duplicates, re-specifies, or overrides them.

### Project setup & stack decisions

| Situation | Skill |
|---|---|
| New project; picking any stack layer | This document's stack + services tables — deviate only with a named override factor |
| Brainstorming / fuzzy requirements | `agent-skills:team-composer` (preferred) |
| Turning an idea into a spec / PRD | `product-management:write-spec` |
| Architecture decision worth recording | `engineering:architecture` (ADR) |
| Stress-testing a plan | `codex:adversarial-review` (already hooked) |

Plan shape and gating (Expected/Realized Outcomes, complexity threshold) belong to kerby's Plan
Gate — don't layer another planning skill on top (hard rule 5).

### Design & UI — decision order

Work down this list; stop at the first match. (Fallback when none of these are installed:
Anthropic's `frontend-design`.)

1. **`DESIGN.md` exists** → follow it. Use `impeccable` as the working verb set
   (`shape` → `craft` → `critique` → `audit` → `polish`) to execute within that system.
2. **`DESIGN.md` missing** → stop and ask the user to run `agent-skills:brand-workshop` (it
   produces the starter `DESIGN.md`). Don't invent a brand, and don't substitute another
   generator on your own. (`ui-ux-pro-max` stays available on explicit request for a reasoned
   design-system exploration — its output gets reconciled into `DESIGN.md`, which remains the SSOT.)
3. **A specific visual direction is named** → the matching `taste-skill:*` variant:
   `minimalist-ui`, `industrial-brutalist-ui`, `high-end-visual-design` (soft/premium),
   `gpt-taste` (strict GSAP/variance). General anti-slop default: `design-taste-frontend` (v2);
   pin `design-taste-frontend-v1` only for backward compatibility.
4. **Checking a UI page or component** → `agent-skills:screenwright`, when it makes sense — i.e.
   when the surface warrants the render-verify loop (build, screenshot, a11y-audit, fix). Skip it
   for trivial tweaks.
5. **Redesigning an existing UI** → `taste-skill:redesign-existing-projects`, or
   `/impeccable audit` → `polish` when the project already uses impeccable (rule 3: incumbent wins).
6. **Design-reference images before coding** → `taste-skill:imagegen-frontend-web` /
   `imagegen-frontend-mobile` / `image-to-code` (image → analyze → implement).

Targeted design tasks (compatible with whichever system is active):

| Situation | Skill | Role lens (alternative) |
|---|---|---|
| Accessibility audit (WCAG AA) | `design:accessibility-review`, or `/impeccable audit` if impeccable is active | `@accessibility_specialist` |
| Structured design feedback on a mockup/screen | `design:design-critique` | `@senior_product_designer` |
| Design-system audit / documentation / extension | `design:design-system` | `@design_engineer` |
| Dev handoff spec from a design | `design:design-handoff` | `@design_engineer` |
| Microcopy, error messages, empty states, CTAs | `design:ux-copy` | `@senior_copywriter` |
| Naming (features, components, products) | — | `@naming_specialist` |
| Truncated / placeholder-riddled output | `taste-skill:full-output-enforcement` | — |
| Brand identity from scratch (logo, tagline, starter DESIGN.md) | `agent-skills:brand-workshop` | — (runs its own panel) |
| Pixel-art assets | `agent-skills:pixel-art` | — |

Role lenses come from `team-composer`'s catalog (`references/role-personas.md`). Run a single lens
via `agent-skills:wear-the-hat`; convene `agent-skills:team-composer` only when the task genuinely
needs multiple perspectives. Choose **one** path per task — official skill or role lens, never
both. Prefer the skill when its structured output is the deliverable; prefer the role lens when a
persona's judgment and voice are what's needed.

### Build, debug & code quality

| Situation | Skill |
|---|---|
| Test strategy / coverage design | `engineering:testing-strategy` |
| Hard bug or performance regression | `diagnose` (preferred), else `superpowers:systematic-debugging` / `engineering:debug` — pick one |
| "Simplest thing that works" pressure | `ponytail` (lite/full/ultra); harvest deferred shortcuts with `ponytail-debt` |
| Over-engineering hunt | `ponytail-review` (diff) / `ponytail-audit` (whole repo) |
| Code review | `codex:review` — already hooked before PR creation; don't stack another reviewer on top. Acting on received feedback: `superpowers:receiving-code-review` |
| Isolated feature work | `superpowers:using-git-worktrees` |
| Technical writing (READMEs, runbooks, API docs) | `engineering:documentation` |
| Localization — all i18n, locale-file, and translation work | `agent-skills:i18n` (default path) |
| Repo governance / conformance audit | `kerby` — explicit invocation only (hard rule 4) |

### Review, QA & shipping

| Situation | Skill |
|---|---|
| Score a site or flow end-to-end in a real browser | `qa:qa` |
| Pre-deploy verification | `engineering:deploy-checklist` |
| Wrapping a dev branch (merge / PR / cleanup) | `superpowers:finishing-a-development-branch` |

### AI features (when the product ships AI)

| Situation | Skill |
|---|---|
| Pre-launch design review of an AI feature (trust, hallucination, provenance, injection) | `agent-skills:ai-ux-review` |
| Eval-rigor review (ground truth, cohorts, adversarial, drift) | `agent-skills:ai-eval-review` |
| Safety-first framing for AI product decisions | `ai-safety-mindset` |
| Should this feature be gamified at all | `agent-skills:gamification-fit` |
| Building an MCP server as part of the stack | `mcp-builder` |

### Thinking & orchestration

| Situation | Skill |
|---|---|
| Multi-perspective decision (architecture review, contested design call) | `agent-skills:team-composer` |
| One expert lens on a task (`@security_specialist`, `@accessibility_specialist`, …) | `agent-skills:wear-the-hat` |
| Parallelizable multi-step work (>15 min, independent chunks) | `agent-skills:sub-agent-coordinator`; `superpowers:dispatching-parallel-agents` for simple fan-out |
| Product/business layer (identity → canvas → tests → deck → grill → GTM) | `agent-skills` startup pipeline — each step gates the next; never bypass gates |
| Writing or auditing a skill itself | `skill-creator` (build/benchmark) / `agent-skills:skill-evaluator` (does the text land) |

---

## Cross-cutting conventions

- **Cost-of-error gate (beyond kerby's hooks).** kerby blocks destructive git; everything else
  irreversible — production deploys, data deletion, spending money, anything sent as the user —
  still requires a stop-and-ask.
- **Failure-first on design calls.** Name the default-but-wrong move before committing to an
  approach; skip for trivial tasks.
- **Calculation policy.** Anything involving money or multi-step math runs through a script, with
  code and raw output shown.

---

## Maintenance

- When a skill's scope changes, only its routing line here should need updating — details live in
  each skill's own `SKILL.md`; kerby's rules live only in kerby (hard rule 5).
- The stack and services tables are this document's own opinion, reflecting 2026-era tooling —
  review them periodically; there is no upstream source to defer to.
- Availability drift is expected. This document must remain safe to load in an environment where
  none of the named plugins are installed (see the availability rule above).
