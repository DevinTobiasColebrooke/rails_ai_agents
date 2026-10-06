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

## Usage
```sh
planning-init /path/to/project   # copies missing files, then runs bin/kanban init
```

`bin/kanban init` creates `docs/planning/` (board + `board.schema.json`) and is
idempotent — it never overwrites an existing board.

Lanes are **opt-in**: a project starts with the base board. Add
`docs/planning/lanes.json` and use `bin/lane` when you want parallel swarms;
`bin/kanban` only seeds lane shards when a lane registry exists.
