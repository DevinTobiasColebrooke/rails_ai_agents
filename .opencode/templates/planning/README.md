# Planning board scaffold

Distributed by the OpenCode setups repo. Installed into a project by
`~/.config/opencode/bin/planning-init` (or `/swarm/init`).

## Contents
- `bin/kanban` — scaffold/validate CLI (`init | check | schema | status`)
- `bin/lane` — worktree/DB/port manager for parallel swarms (opt-in)
- `script/shard_kanban.rb` — seed lane boards from the global board
- `script/rollup_kanban.rb` — push lane shards back up to the global board

## Usage
```sh
planning-init /path/to/project   # copies missing files, then runs bin/kanban init
```

`bin/kanban init` creates `docs/planning/` (board + `board.schema.json`) and is
idempotent — it never overwrites an existing board.

Lanes are **opt-in**: a project starts with the base board. Add
`docs/planning/lanes.json` and use `bin/lane` when you want parallel swarms;
`bin/kanban` only seeds lane shards when a lane registry exists.
