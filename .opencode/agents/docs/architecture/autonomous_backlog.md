# Autonomous Backlog Architecture

This document defines the file-based database used for asynchronous agent collaboration.

## Directory Structure
- `docs/planning/epics/`: High-level features (Markdown).
- `docs/planning/tickets/`: Units of work.
  - `pending/`: Ready for pickup (Features, Bugs, Chores).
  - `active/`: Currently being implemented by an agent.
  - `completed/`: Finished and verified.
- `docs/planning/test_cases/`: QA Artifacts.
  - `plans/`: Test Strategies linked to Epics.
  - `cases/`: Atomic test scenarios (Gherkin).
  - `runs/`: Execution reports.
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

### 3. Test Plan (`TP-{epic_id}.md`)
```markdown
# Test Plan: User Authentication
**Epic:** E-001
**Strategy:**
- Unit: Model validations for Email.
- System: Capybara flow for Magic Link login.
- E2E: Playwright check for email delivery simulation.
```

### 4. Test Case (`TC-{ticket_id}-{id}.md`)
```markdown
# TC-101-01: Login with Valid Email
**Linked Ticket:** T-101
**Type:** Regression | Smoke

Scenario:
  Given I am on "/login"
  When I fill "email" with "test@example.com"
  And I click "Send Magic Link"
  Then I should see "Check your email"
```

## Agent Protocols

### Checkout Protocol (Pickup)
1. Agent reads `docs/planning/tickets/pending`.
2. Agent moves file to `docs/planning/tickets/active`.
3. Agent updates `kanban_state.json` adding `"T-101": "@agent_name"`.

### Completion Protocol (Delivery)
1. Agent runs local tests (GREEN).
2. Agent moves file to `docs/planning/tickets/completed`.
3. Agent triggers `@qa-manager` for verification.

### QA Protocol (Verification)
1. `@qa-manager` executes linked Test Cases.
2. If Pass: Ticket remains in `completed`.
3. If Fail: 
   - `@qa-manager` moves ticket back to `active` OR creates new `T-BUG` ticket.
   - `@qa-manager` generates `docs/planning/tickets/pending/T-BUG-{id}.md`.