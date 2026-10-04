---
description: Equip this project with the planning board scaffold and initialise it
---

Equip the project with the shared planning board and report what changed:

!`"$HOME/.config/opencode/bin/planning-init" "$PWD" 2>/dev/null || bin/kanban init 2>/dev/null || echo "(planning-init unavailable — is the OpenCode setups repo synced?)"`

The board lives at `docs/planning/kanban_state.json`. Never hand-edit it: lanes
write their own shard under `docs/planning/lanes/<lane>/`, `script/shard_kanban.rb`
seeds shards, and `script/rollup_kanban.rb` rolls shards back up to the global board.
