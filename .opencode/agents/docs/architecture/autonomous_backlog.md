# Autonomous Backlog Architecture

This document defines the file-based database used for asynchronous agent collaboration.

## Directory Structure
- `docs/planning/epics/`: High-level features (Markdown).
- `docs/planning/tickets/`: Units of work.
  - `pending/`: Ready for pickup.
  - `active/`: Currently being implemented by an agent.
  - `completed/`: Finished and verified.
- `docs/planning/kanban_state.json`: Real-time summary for the Project Manager.

## Data Schemas

### 1. Epic (`E-{id}-{slug}.md`)
```markdown
# Epic: User Authentication
**Status:** Active
**Priority:** High

## Description
Implement passwordless authentication using magic links.

## Scope
- [ ] Database Schema (Identities, Sessions)
- [ ] Mailers
- [ ] Controllers
```

### 2. Ticket (`T-{id}-{slug}.md`)
```markdown
# Ticket: Create Identity Model
**Epic:** E-001
**Type:** Feature | Bug | Chore
**Assigned:** @model-agent (when active)

## Requirements
1. Create table `identities` with UUID.
2. Add index on `email_address`.

## Context
- Reference: `docs/blueprint/domain_class_diagram.mermaid`
```

## Agent Protocols

### Checkout Protocol (Pickup)
1. Agent reads `docs/planning/tickets/pending`.
2. Agent moves file to `docs/planning/tickets/active`.
3. Agent updates `kanban_state.json` adding `"T-101": "@agent_name"`.

### Completion Protocol (Delivery)
1. Agent runs tests (GREEN).
2. Agent moves file to `docs/planning/tickets/completed`.
3. Agent updates `kanban_state.json` removing assignment.
4. Agent triggers `@review-agent` on the generated code.