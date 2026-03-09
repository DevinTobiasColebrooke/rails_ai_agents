# Project Plan: The Rails 8 Domain Swarm

## 1. System Philosophy & Stack

**Objective:** Autonomous construction of a production-ready Rails application via specialized agent orchestration.
**Core Philosophy:** "Fat Models, Skinny Controllers, Solid Infrastructure."

### The Tech Stack
- **App:** Ruby 3.3+, Rails 8.2+ (Edge), PostgreSQL (Production) / SQLite (Dev).
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS v4.
- **Infrastructure:** The "Solid" Stack (Solid Queue, Solid Cache, Solid Cable).
- **Deployment:** Docker + Kamal 2.
- **Testing:** Minitest (Unit/Integration) + Capybara/Selenium (System).

---

## 2. The Agent Swarm Registry

The agents are organized by their operational layer. Every agent file serves a specific purpose in the lifecycle.

### Phase 1: Product Strategy (The "Why")

#### 1a. The Product Strategist
*File: `agents/product-strategist.md`*
- **Role:** The Visionary.
- **Responsibility:** Defines the "North Star," User Personas, and strict MVP boundaries (Anti-Goals).
- **Output:** `docs/blueprint/product_vision.md`.

#### 1b. The Requirements Specialist
*File: `agents/requirements-specialist.md`*
- **Role:** The Analyst.
- **Responsibility:** Converts vision into concrete Functional Requirements, Business Rules, and Entity Lists ("Nouns").
- **Output:** `docs/blueprint/requirements_spec.md`.

#### 1c. The User Journey Mapper
*File: `agents/user-journey-mapper.md`*
- **Role:** The UX Director.
- **Responsibility:** Maps Happy Paths and Sad Paths. Writes Gherkin-style User Stories to define behavior.
- **Output:** `docs/blueprint/user_stories.md`.

### Phase 2: Planning & Architecture (The "How")

#### 2a. The Autopilot Agent
*File: `agents/autopilot-agent.md`*
- **Role:** The Product Owner.
- **Responsibility:** Reads the User Stories and **decomposes** them into the file-based Backlog.
- **Output:** `docs/planning/epics/*.md` and `docs/planning/tickets/pending/*.md`.

#### 2b. The Project Manager
*File: `agents/project-manager.md`*
- **Role:** The Scrum Master.
- **Responsibility:** Maintains Kanban integrity. Scans directories to update status JSON and assigns agents to tickets.
- **Output:** `docs/planning/kanban_state.json`.

#### 2c. The System Architect
*File: `agents/system-architect.md`*
- **Role:** The City Planner.
- **Responsibility:** Defines directory structure and maps features to infrastructure (e.g., "This needs Solid Queue").
- **Output:** `docs/blueprint/architecture_map.md`.

#### 2d. The Domain Modeler
*File: `agents/domain-modeler.md`*
- **Role:** The Logic Architect.
- **Responsibility:** Designs Ruby classes, identifies Concerns, and defines Method Signatures *before* coding.
- **Output:** `docs/blueprint/domain_class_diagram.mermaid`.

#### 2e. The Schema Architect
*File: `agents/schema-architect.md`*
- **Role:** The Database Engineer.
- **Responsibility:** Translates domain models into rigid SQL schemas (UUIDs, Indexes, Constraints).
- **Output:** `docs/blueprint/schema_plan.rb`.

#### 2f. The Technical Librarian
*File: `agents/technical-librarian.md`*
- **Role:** The Gatekeeper.
- **Responsibility:** Validates Gem compatibility and enforces the "Solid Stack" (No Node/Redis).
- **Output:** `docs/blueprint/tech_stack.md`.

#### 2g. The Design System Lead
*File: `agents/design-system-lead.md`*
- **Role:** The Stylist.
- **Responsibility:** Defines Tailwind configuration, color palettes, and Turbo transition patterns.
- **Output:** `docs/blueprint/design_system.md`.

### Phase 3: Construction (The Builders)

#### 3a. The Implement Agent (Rails Artisan)
*File: `agents/implement-agent.md`*
- **Role:** The Lead Engineer / Orchestrator.
- **Responsibility:** The primary worker. Picks up a Ticket and delegates tasks to the specialized sub-agents below.

#### The Specialized Sub-Agents:
1.  **@migration-agent** (`agents/migration-agent.md`): Schema ops, UUIDs, Indexes.
2.  **@model-agent** (`agents/model-agent.md`): ActiveRecord logic, Associations.
3.  **@concerns-agent** (`agents/concerns-agent.md`): Shared behavior extraction.
4.  **@state-records-agent** (`agents/state-records-agent.md`): State machines (No booleans).
5.  **@crud-agent** (`agents/crud-agent.md`): REST controllers.
6.  **@api-agent** (`agents/api-agent.md`): JSON APIs, Jbuilder.
7.  **@auth-agent** (`agents/auth-agent.md`): Authentication, Current attributes.
8.  **@multi-tenant-agent** (`agents/multi-tenant-agent.md`): Account scoping rules.
9.  **@turbo-agent** (`agents/turbo-agent.md`): Streams, Frames, Broadcasting.
10. **@stimulus-agent** (`agents/stimulus-agent.md`): JavaScript behaviors.
11. **@tailwind-agent** (`agents/tailwind-agent.md`): UI Styling (Views/Components).
12. **@jobs-agent** (`agents/jobs-agent.md`): Background processing.
13. **@events-agent** (`agents/events-agent.md`): Domain events, Audit trails.
14. **@mailer-agent** (`agents/mailer-agent.md`): Transactional emails.
15. **@caching-agent** (`agents/caching-agent.md`): HTTP/Fragment caching.
16. **@test-agent** (`agents/test-agent.md`): Writing Minitest/Fixtures.

### Phase 4: Maintenance & Optimization

#### 4a. The Refactoring Agent
*File: `agents/refactoring-agent.md`*
- **Role:** The Modernizer.
- **Responsibility:** Audits existing code to fix anti-patterns (e.g., "Convert Service Object to Model Method").

### Phase 5: Verification & Delivery

#### 5a. The QA Manager
*File: `agents/qa-manager.md`*
- **Role:** QA Lead.
- **Responsibility:**
    1.  Creates Test Plans (`TP-*`) linked to Epics.
    2.  Creates Test Cases (`TC-*`) linked to Tickets.
    3.  Orchestrates Sub-Agents (`user-proxy`, `playwright-agent`) to verify implementation.
    4.  Files `T-BUG-*` tickets in the backlog upon failure.
- **Output:** `docs/planning/test_cases/*` and Bug Tickets.

#### 5b. The Code Warden (Review Agent)
*File: `agents/review-agent.md`*
- **Role:** Static Analysis.
- **Responsibility:** Reviews code against style guides. Rejects fat controllers or anemic models.

#### 5c. The User Proxy (Sub-Agent of QA)
*File: `agents/user-proxy.md`*
- **Role:** Automated Tester.
- **Responsibility:** Runs Capybara System Tests to verify Hotwire interactions (no page reloads).

#### 5d. The Playwright Agent (Sub-Agent of QA)
*File: `agents/playwright-agent.md`*
- **Role:** Interactive Tester.
- **Responsibility:** "Remote hands" for visual verification and complex E2E flows via CLI.

#### 5e. The SecOps Sentinel
*File: `agents/secops-sentinel.md`*
- **Role:** Security Auditor.
- **Responsibility:** Checks for Mass Assignment, IDOR (Scoping), and dependency vulnerabilities.

#### 5f. The Release Agent
*File: `agents/release-agent.md`*
- **Role:** Release Manager.
- **Responsibility:** Triggered after QA verification. Manages git version control, semantic commits, and GitHub Pull Requests for the completed ticket.

### Phase 6: Operations & Documentation

#### 6a. The SRE Agent
*File: `agents/sre-agent.md`*
- **Role:** DevOps.
- **Responsibility:** Generates `Dockerfile` and Kamal `deploy.yml` for production.

#### 6b. The Scribe Agent
*File: `agents/scribe-agent.md`*
- **Role:** Technical Writer.
- **Responsibility:** Generates README, API Docs, and Changelogs based on the final codebase.

---

## 3. The Autonomous Lifecycle Workflow

1.  **Define:** Strategist + Requirements Specialist + Journey Mapper create the specs.
2.  **Plan:** Autopilot Agent generates the Backlog. Project Manager tracks it.
3.  **Design:** Architects (System, Domain, Schema, Design, Librarian) create the Blueprints.
4.  **Build:** Implement Agent reads Blueprints/Tickets and orchestrates Sub-Agents to write code.
5.  **Verify & Deliver:**
    *   Code Warden checks style.
    *   SecOps Sentinel checks security.
    *   User Proxy checks functionality (System Tests).
    *   Playwright Agent checks visuals (Browser).
    *   Release Agent commits changes, pushes branch, and opens PR (only on successful verification).
6.  **Refine:** Refactoring Agent optimizes technical debt.
7.  **Ship:** SRE Agent configures deploy; Scribe Agent writes docs.
## 4. The Contractor Agents (Out-of-Band)

These agents operate outside the standard software development lifecycle. They act as independent consultants brought in for specialized, high-level, or periodic tasks rather than step-by-step ticket execution.

#### 4a. The Trend Scout Agent
*File: `agents/trend-scout-agent.md`*
- **Role:** The Market Researcher.
- **Responsibility:** Identifies niches, sociological trends, problems, and pain points. Scours the internet to provide product ideas and draft detailed product concepts for new applications.

#### 4b. The Feature Agent
*File: `agents/feature-agent.md`*
- **Role:** The Product Consultant.
- **Responsibility:** Analyzes an existing application, its context, and user needs to recommend valuable new features to add to the product roadmap.

#### 4c. The QE Agent
*File: `agents/qe-agent.md`*
- **Role:** The External Auditor.
- **Responsibility:** Acts as a fresh set of testing eyes on an application. Provides independent quality engineering, exploratory testing, and edge-case discovery separate from the standard QA Manager's rigorous ticket loop.
