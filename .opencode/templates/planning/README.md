# Planning board scaffold

Distributed by the OpenCode setups repo. Installed into a project by
`~/.config/opencode/bin/planning-init` (or `/swarm/init`).

## Contents
- `bin/kanban` — scaffold/validate CLI (`init | check | schema | status`)
- `bin/lane` — worktree/DB/port manager for parallel swarms (opt-in)
- `bin/swarm` — per-swarm worktree/DB/port provisioner (opt-in)
- `script/shard_kanban.rb` — seed lane boards from the global board
- `script/rollup_kanban.rb` — push lane shards back up to the global board
- `script/planning_guard.rb` — rebase with planning set aside; never uses `git stash`

## Never `git stash` in a worktree
`refs/stash` is shared by every worktree, so stashing uncommitted `docs/planning`
edits during a rebase can leak another swarm's work. Rebase safely instead:

```sh
bin/swarm sync <n> [--base main]      # swarm worktree
bin/lane  sync <lane> [--base main]   # lane worktree
```

These move the dirty planning paths aside, rebase, and put them back — no stash.

## `bin/swarm finish` hook
`bin/swarm finish` runs `script/reconcile_swarm.rb` (if the project provides it) **before**
it removes the worktree. The scaffold ships no reconcile script — a project implements one
to preserve its lane planning artifacts and update its own backlog. Inputs arrive via the
environment:

```
SWARM_N          swarm number
SWARM_LANE       lane label
SWARM_WORKTREE   the swarm worktree path
SWARM_MAIN       the main (integration) checkout path
SWARM_MERGED     "1" if the branch is merged into main, else "0"
```

`--no-reconcile` skips the hook; a non-zero hook exit **aborts teardown** so nothing is lost.
The hook writes to the integration checkout only — the resulting changes still land through
the normal reconciliation PR.

## Usage
```sh
planning-init /path/to/project   # copies missing files, then runs bin/kanban init
```

`bin/kanban init` creates `docs/planning/` (board + `board.schema.json`) and is
idempotent — it never overwrites an existing board.

Lanes are **opt-in**: a project starts with the base board. Add
`docs/planning/lanes.json` and use `bin/lane` when you want parallel swarms;
`bin/kanban` only seeds lane shards when a lane registry exists.
