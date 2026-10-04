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

## Land

- Commit **code only**: `git add` explicit paths, never `docs/planning/**`.
- Open a PR from the swarm branch.

## Clean up (after the PR merges)

A swarm **cannot remove its own worktree while its session is inside it**, so:

1. **Relocate the session back to the main checkout** (the integration lane).
2. Run `bin/swarm finish <n>`. It refuses if the branch is not merged into `main` — pass
   `--force` only to discard abandoned work. It removes the worktree, deletes the branch,
   and drops the swarm's databases.

`@project-manager` / the release agent may also sweep finished swarms: `bin/swarm list`,
then `bin/swarm finish <n>`. Never finish a swarm whose workspace is still active.

## Commands

```sh
bin/swarm start [--lane NAME] [--prepare]   # provision; prints SWARM_JSON + ID blocks
bin/swarm list                              # active swarms
bin/swarm env <n>                           # shell exports for swarm N
bin/swarm run <n> -- <cmd...>               # run a command in swarm N's worktree
bin/swarm finish <n> [--force]              # teardown (merged-branch guard unless --force)
```

## Rules

- One swarm per `opencode` window; never two swarms in one worktree.
- A swarm writes only its own lane shard, inside its own worktree.
- Never commit planning from a swarm branch; the global board is a read-only rollup owned
  by `@project-manager`.
- The user types no CLI — you run `bin/swarm`, `bin/lane`, and `bin/kanban`.
