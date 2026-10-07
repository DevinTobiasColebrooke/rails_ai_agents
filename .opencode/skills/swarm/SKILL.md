---
name: Swarm
description: Run and manage parallel agent swarms in an existing project without the user typing CLI. Use when the user asks for a feature, fix, or change in an existing repo, or when provisioning an isolated swarm workspace, filing lane-scoped tickets, landing a code-only PR, reconciling the planning board, or tearing a swarm down.
---

# Swarm

Run a feature/fix/change in an **existing project** as an isolated parallel swarm. The
user opens `opencode` in the repo and describes the work; you (the agent) provision the
isolation and do the work. The user types no CLI.

## Mental model

- **Isolation unit = the swarm**, not the lane. A swarm has its own git worktree, branch,
  Postgres database, and ports. Many swarms may share a lane label and still run in
  parallel.
- **Lane = a label** used to classify work and pick a reserved ticket-ID block.
- **The main checkout is the integration lane** — never build there.
- **Planning lives in the swarm's worktree**, and a swarm **never commits
  `docs/planning/**`**. `@project-manager` reconciles the board after the PR merges, so
  parallel branches never conflict on the board.

## Planning root

Resolve before touching `docs/planning/`:

```sh
LANE="${LANE:-$(cat .lane 2>/dev/null)}"
```

- Lane active → root is `docs/planning/lanes/$LANE/` (board, tickets, `test_cases/`).
- No lane → the global `docs/planning/kanban_state.json` and `docs/planning/tickets/…`.

Never write the global `kanban_state.json` while a lane is active. `docs/ideas_and_todos.md`
and `docs/blueprint/**` are read-only inputs.

## Provision (when no swarm is active)

1. **Classify** the request to a lane via `name` / `owns` / `epics` in
   `docs/planning/lanes.json`. If none fit, use `default`. If the request spans lanes,
   pick the primary lane and file cross-linked *satellite* tickets in the others.
2. Run `bin/swarm start --lane <lane> --prepare`. It prints a line
   `SWARM_JSON: {…}` with `worktree`, `branch`, `database`, `port`, `ticket_block`,
   `bug_block`.
3. **Relocate this session into that `worktree`** (session move) so all later work — yours
   and every subagent's — happens there. The worktree carries a `.lane` marker, so the
   planning root resolves to `docs/planning/lanes/<lane>/`.
4. If `bin/swarm` is missing, run
   `$HOME/.config/opencode/bin/planning-init "$PWD"` once to install the scaffold, or fall
   back to `bin/lane create <lane>` + session move.

## Do the work

- File the ticket via `@user-journey-mapper`, planning root `docs/planning/lanes/<lane>/`,
  using an ID from this swarm's `ticket_block` (features/chores) or `bug_block` (bugs).
  Never allocate outside the block. Never touch the global board.
- Run the verification loop: `@implement-agent` → `@review-agent` → `@qa-manager`
  (Phase 4 of the autopilot workflow). Bugs before features.

## Worktree hygiene — never `git stash`

`refs/stash` is **shared by every worktree** in the repo. `git stash` in one swarm is
visible in all the others, and `git stash pop` can consume another swarm's entry or apply
its changes into your tree. A swarm's uncommitted `docs/planning/**` edits are the usual
reason a rebase refuses to run — **do not stash them.**

Rebase safely instead; it backs up the dirty planning paths, resets the tree, rebases, and
puts them back (no stash):

```sh
bin/swarm sync <n> [--base main]      # swarm worktree
bin/lane  sync <lane> [--base main]   # lane worktree
```

If a `refs/stash` entry already exists, leave it alone — it may belong to another swarm.

## Land

- Commit **code only**: `git add` explicit paths, never `docs/planning/**`.
- Open a PR from the swarm branch.

## Clean up (after the PR merges)

A swarm **cannot remove its own worktree while its session is inside it**, so:

1. **Relocate the session back to the main checkout** (the integration lane).
2. Run `bin/swarm finish <n>`. It refuses if the branch is not merged into `main` — pass
   `--force` only to discard abandoned work. **Before teardown it runs the project's
   reconcile hook** (`script/reconcile_swarm.rb`, if present) to preserve the swarm's lane
   planning artifacts and record shipped tickets; `--no-reconcile` skips it, and a hook
   failure aborts teardown so nothing is lost. Then it removes the worktree, deletes the
   branch, and drops the swarm's databases.

`@project-manager` / the release agent may also sweep finished swarms: `bin/swarm list`,
then `bin/swarm finish <n>`. Never finish a swarm whose workspace is still active.

## Reconcile (planning board lands via PR)

`@project-manager` reconciles the finished swarm's lane artifacts into the integration
lane — but the reconciliation is **itself landed through a pull request**, never a direct
push to `main`.

- `bin/swarm finish` performs the artifact copy (and any project backlog annotation) into
  the integration checkout, but it **never commits** — the resulting `docs/planning/**`
  changes still land through the PR flow below.
- **Never** commit `docs/planning/**` straight to `main`, and **never** set
  `ALLOW_MAIN_PUSH=1` (or otherwise bypass `.githooks/pre-push`). The hook exists because
  direct `main` pushes skip review and the `lanes.yml` board guard, and once exhausted the
  repo's Actions budget. A direct push is a process violation even when the content is
  docs-only.
- Flow: branch off `origin/main` → apply the reconciliation → push the branch → open a PR
  (the cheap, dependency-free `lanes.yml` guard runs on `docs/planning/**`) → merge.
- If more artifacts land in the live checkout after a sweep, run a follow-up sweep through
  the same PR flow; do not "top up" with a direct push.
- The merged code PR and the planning-reconciliation PR are separate: the code PR is opened
  from the swarm branch; the reconciliation PR is opened from the integration lane by
  `@project-manager`.

## Commands

```sh
bin/swarm start [--lane NAME] [--prepare]   # provision; prints SWARM_JSON + ID blocks
bin/swarm list                              # active swarms
bin/swarm env <n>                           # shell exports for swarm N
bin/swarm run <n> -- <cmd...>               # run a command in swarm N's worktree
bin/swarm sync <n> [--base REF]             # rebase; moves planning aside (never stash)
bin/swarm finish <n> [--force]              # teardown (merged-branch guard unless --force)
```

## Rules

- One swarm per `opencode` window; never two swarms in one worktree.
- Never `git stash` in a worktree — the stash stack is shared; use `bin/swarm sync`.
- A swarm writes only its own lane shard, inside its own worktree.
- Never commit planning from a swarm branch; the global board is a read-only rollup owned
  by `@project-manager`.
- Planning reconciliation reaches `main` **only via a PR** — never a direct push, never
  `ALLOW_MAIN_PUSH=1`.
- The user types no CLI — you run `bin/swarm`, `bin/lane`, and `bin/kanban`.
