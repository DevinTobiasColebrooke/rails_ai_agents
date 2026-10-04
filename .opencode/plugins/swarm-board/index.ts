import { Plugin } from "@opencode/plugin"
import { existsSync, mkdirSync, writeFileSync } from "node:fs"
import { join } from "node:path"

// Global copy of the swarm-board plugin. Ensures the shared planning board
// exists. Opt-in: only projects that ship a `bin/kanban` are scaffolded, so
// opening an unrelated repo is a no-op.
//
// Registers a `kanban_init` tool and a prompt-admission hook.

const DIRS: readonly (readonly string[])[] = [
  ["docs", "planning", "epics"],
  ["docs", "planning", "tickets", "pending"],
  ["docs", "planning", "tickets", "active"],
  ["docs", "planning", "tickets", "completed"],
  ["docs", "planning", "test_cases", "plans"],
  ["docs", "planning", "test_cases", "cases"],
  ["docs", "planning", "test_cases", "runs"],
]

const SKELETON =
  JSON.stringify(
    {
      columns: { pending: [], active: [], completed: [] },
      epics: {},
      next_ticket_id: "T-1",
      next_bug_id: "T-BUG-1",
      tickets: {},
    },
    null,
    2,
  ) + "\n"

export default Plugin.define({
  id: "swarm-board",
  async setup(ctx) {
    const root = ctx.location.directory
    const board = join(root, "docs", "planning", "kanban_state.json")
    const initScript = join(root, "bin", "kanban")

    const ensure = (): boolean => {
      if (existsSync(board)) return false
      if (!existsSync(initScript)) return false
      for (const parts of DIRS) mkdirSync(join(root, ...parts), { recursive: true })
      writeFileSync(board, SKELETON)
      return true
    }

    await ctx.tool.transform((editor) => {
      editor.add({
        name: "kanban_init",
        description:
          "Scaffold the shared kanban board at docs/planning/ if missing. Idempotent.",
        input: { type: "object", properties: {}, additionalProperties: false },
        execute: async () => ({
          content: ensure()
            ? "Scaffolded docs/planning/ (board + ticket/test directories)."
            : "docs/planning/ already present (or this project has no bin/kanban).",
        }),
      })
    })

    await ctx.session.hook("prompt", () => {
      ensure()
    })
  },
})
