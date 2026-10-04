---
description: Scaffold the shared kanban board (docs/planning) if this project has bin/kanban
---

Initialise the planning board and report what changed:

!`bin/kanban init 2>/dev/null || echo "(no bin/kanban in this project — copy it from the swarm template)"`

The board lives at `docs/planning/kanban_state.json`. Never hand-edit it:
lanes write their own shard under `docs/planning/lanes/<lane>/`,
`script/shard_kanban.rb` seeds shards, and `script/rollup_kanban.rb` rolls
shards back up to the global board.
