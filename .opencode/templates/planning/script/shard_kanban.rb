#!/usr/bin/env ruby
# frozen_string_literal: true

# shard_kanban.rb — maintain per-lane Kanban board shards.
#
# The global docs/planning/kanban_state.json is the read-only rollup/history.
# Each active lane has its own board at:
#
#   docs/planning/lanes/<lane>/kanban_state.json
#
# Routing is epic_id -> lane via docs/planning/lanes.json; unmapped epics land
# in the `archive` lane.
#
# Usage:
#   ruby script/shard_kanban.rb             # dry run: report routing only
#   ruby script/shard_kanban.rb --write     # additive seed: add tickets a lane
#                                           # is missing; NEVER remove/overwrite
#                                           # a lane's own edits
#   ruby script/shard_kanban.rb --charters  # (re)generate lane.md charters
#   ruby script/shard_kanban.rb --check     # CI hygiene gate (exit 1 on error)
#
# Safe to re-run. Never mutates the global board. To push lane edits back up to
# the global board, use script/rollup_kanban.rb.

require "json"
require "fileutils"
require "set"

ROOT         = File.expand_path("..", __dir__)
PLANNING     = File.join(ROOT, "docs", "planning")
LANES_JSON   = File.join(PLANNING, "lanes.json")
GLOBAL_BOARD = File.join(PLANNING, "kanban_state.json")
LANES_DIR    = File.join(PLANNING, "lanes")

module Shard
  COLUMNS = %w[pending active completed].freeze

  module_function

  def lanes_config
    JSON.parse(File.read(LANES_JSON))
  end

  def global_board
    JSON.parse(File.read(GLOBAL_BOARD))
  end

  # epic_id => lane_id
  def epic_map(config)
    map = {}
    config["lanes"].each do |lane|
      Array(lane["epics"]).each { |epic| map[epic] = lane["id"] }
    end
    map
  end

  def route(tickets, epic_map)
    by_lane = Hash.new { |h, k| h[k] = { pending: [], active: [], completed: [], meta: {} } }
    tickets.each do |slug, t|
      lane = epic_map[t["epic_id"]] || "archive"
      status = (t["status"] || "pending").to_s
      bucket = case status
      when "pending" then :pending
      when "active" then :active
      else :completed
      end
      by_lane[lane][bucket] << slug
      by_lane[lane][:meta][slug] = t if bucket != :completed
    end
    by_lane
  end

  def lane_board(config, lane, routed)
    bucket = routed[lane["id"]]
    {
      "lane" => lane["id"],
      "name" => lane["name"],
      "generated_from" => "docs/planning/kanban_state.json",
      "id_blocks" => {
        "ticket" => lane["ticket_block"],
        "bug" => lane["bug_block"]
      },
      "branch" => lane["branch"],
      "worktree" => lane["worktree"],
      "database" => lane["database"],
      "ports" => lane["ports"],
      "columns" => {
        "pending" => bucket[:pending].sort,
        "active" => bucket[:active].sort,
        "completed" => bucket[:completed].sort
      },
      "next_ticket_id" => first_of_block(lane["ticket_block"]),
      "next_bug_id" => first_of_block(lane["bug_block"]),
      "tickets" => bucket[:meta].sort.to_h,
      "note" => "Shard board. Completed history + full rollup live in docs/planning/kanban_state.json (owned by @project-manager)."
    }
  end

  def first_of_block(block)
    return nil unless block
    block.split("..").first
  end

  # Additive merge: add slugs the lane does not already know about; never remove
  # a lane's own entries (so a lane's pending->active move is not resurrected)
  # and never overwrite a lane's own ticket metadata.
  def merge_into(existing, generated)
    merged = existing.dup
    merged["columns"] ||= {}
    COLUMNS.each { |c| merged["columns"][c] ||= [] }
    merged["tickets"] ||= {}

    known = merged["columns"].values.flatten.to_set
    COLUMNS.each do |col|
      generated["columns"][col].each do |slug|
        next if known.include?(slug)
        merged["columns"][col] << slug
        known << slug
      end
    end
    merged["columns"].each_value(&:sort!)

    generated["tickets"].each do |slug, meta|
      merged["tickets"][slug] ||= meta
    end
    merged
  end

  def charter(config, lane)
    owns = Array(lane["owns"]).map { |g| "- `#{g}`" }.join("\n")
    owns = "- _(greenfield — create under this lane)_" if owns.empty?
    reads = Array(lane["reads"]).map { |g| "- `#{g}`" }.join("\n")
    reads = "- _(none declared)_" if reads.empty?
    epics = Array(lane["epics"]).join(", ")
    epics = "_(none yet — new epics are filed under this lane)_" if epics.empty?

    <<~MD
      # Lane: #{lane["name"]} (`#{lane["id"]}`)

      **Status:** #{lane["status"]}
      **Branch:** `#{lane["branch"] || "n/a"}`
      **Worktree:** `#{lane["worktree"] || "n/a"}`
      **Database:** `#{lane.dig("database", "dev") || "n/a"}` / `#{lane.dig("database", "test") || "n/a"}`
      **Ports:** server `#{lane.dig("ports", "server") || "n/a"}`, playwright `#{lane.dig("ports", "playwright") || "n/a"}`
      **Ticket block:** `#{lane["ticket_block"] || "n/a"}`  |  **Bug block:** `#{lane["bug_block"] || "n/a"}`
      **Epics:** #{epics}

      > Generated from `docs/planning/lanes.json`. Edit the registry, not this file,
      > then re-run `ruby script/shard_kanban.rb --charters`.

      ## Owns (sole writer)
      #{owns}

      ## May read (never write without a coordination ticket)
      #{reads}

      ## Rules
      0. Resolve your planning root from `.lane`/`$LANE`; write only under `docs/planning/lanes/#{lane["id"]}/` (board, tickets, test_cases).
      1. Every file has exactly one owning lane. Cross-lane edits require a coordination ticket.
      2. Never hand-edit `db/schema.rb`; rebase then `db:migrate` to regenerate.
      3. Do not edit `Gemfile` / `Gemfile.lock` ad hoc — propose the gem, integration owner adds it.
      4. New routes go in `config/routes/#{lane["id"]}.rb` (bare definitions, auto-drawn) — never edit `config/routes.rb`.
      5. Write only to this lane's board shard; `@project-manager` owns the global rollup.
      6. `docs/ideas_and_todos.md` and `docs/blueprint/**` are read-only.

      ## Bring-up
      ```sh
      bin/lane create #{lane["id"]}
      bin/lane env #{lane["id"]}    # export DATABASE_URL / PORT for this shell
      ```
    MD
  end

  def write(config, routed, charters: false)
    FileUtils.mkdir_p(LANES_DIR)
    changed = []
    config["lanes"].each do |lane|
      dir = File.join(LANES_DIR, lane["id"])
      FileUtils.mkdir_p(File.join(dir, "tickets", "pending"))
      FileUtils.mkdir_p(File.join(dir, "tickets", "active"))
      FileUtils.mkdir_p(File.join(dir, "tickets", "completed"))
      %w[pending active completed].each do |c|
        keep = File.join(dir, "tickets", c, ".keep")
        File.write(keep, "") unless File.exist?(keep)
      end

      # QA artifacts are lane-scoped too (mirrors docs/planning/test_cases/).
      %w[plans cases runs].each do |c|
        FileUtils.mkdir_p(File.join(dir, "test_cases", c))
        keep = File.join(dir, "test_cases", c, ".keep")
        File.write(keep, "") unless File.exist?(keep)
      end

      board_path = File.join(dir, "kanban_state.json")
      generated = lane_board(config, lane, routed)
      board = if File.exist?(board_path)
                merge_into(JSON.parse(File.read(board_path)), generated)
      else
                generated
      end
      body = JSON.pretty_generate(board) + "\n"
      if !File.exist?(board_path) || File.read(board_path) != body
        File.write(board_path, body)
        changed << "docs/planning/lanes/#{lane["id"]}/kanban_state.json"
      end

      next unless charters

      charter_path = File.join(dir, "lane.md")
      text = charter(config, lane)
      if !File.exist?(charter_path) || File.read(charter_path) != text
        File.write(charter_path, text)
        changed << "docs/planning/lanes/#{lane["id"]}/lane.md"
      end
    end
    changed
  end

  # ---- hygiene validation (CI gate) -----------------------------------------

  def id_kind_and_number(slug)
    if (m = slug.match(/\AT-BUG-(\d+)/))
      [:bug, m[1].to_i]
    elsif (m = slug.match(/\AT-(\d+)/))
      [:ticket, m[1].to_i]
    end
  end

  def block_range(block)
    return nil unless block
    nums = block.split("..").map { |x| x[/\d+\z/].to_i }
    nums.size == 2 ? (nums[0]..nums[1]) : nil
  end

  def validate(config, routed)
    errors = []

    # 1. no epic assigned to more than one active lane
    seen = {}
    config["lanes"].each do |lane|
      next if lane["status"] == "frozen"
      Array(lane["epics"]).each do |epic|
        if seen[epic]
          errors << "epic #{epic} is claimed by both '#{seen[epic]}' and '#{lane["id"]}'"
        else
          seen[epic] = lane["id"]
        end
      end
    end

    # 2. every lane board exists + parses, IDs are in-block (for lane-local tickets),
    #    and no slug is live in two lanes.
    live = Hash.new { |h, k| h[k] = [] }
    config["lanes"].each do |lane|
      path = File.join(LANES_DIR, lane["id"], "kanban_state.json")
      unless File.exist?(path)
        errors << "lane '#{lane["id"]}': missing #{path.sub("#{ROOT}/", "")}"
        next
      end
      board = begin
        JSON.parse(File.read(path))
      rescue JSON::ParserError => e
        errors << "lane '#{lane["id"]}': invalid JSON (#{e.message})"
        next
      end
      cols = board["columns"] || {}
      %w[pending active].each do |col|
        Array(cols[col]).each do |slug|
          live[slug] << lane["id"]
          meta = (board["tickets"] || {})[slug] || {}
          next unless meta["ticket_file"].to_s.start_with?("docs/planning/lanes/#{lane["id"]}/")

          kind, num = id_kind_and_number(slug)
          next unless kind

          block = kind == :bug ? lane["bug_block"] : lane["ticket_block"]
          range = block_range(block)
          next if range.nil? || range.cover?(num)

          errors << "lane '#{lane["id"]}': #{slug} is outside its #{kind} block #{block}"
        end
      end
    end

    live.each do |slug, lanes|
      next if lanes.uniq.size <= 1
      errors << "#{slug} is live in multiple lanes: #{lanes.uniq.join(', ')}"
    end

    errors
  end

  # ---- reporting -------------------------------------------------------------

  def report(config, routed)
    epic_map = epic_map(config)
    puts "Lane routing (pending/active/completed):"
    config["lanes"].each do |lane|
      b = routed[lane["id"]]
      puts format("  %-12s %3d / %-3d / %-3d   %s",
                  lane["id"], b[:pending].size, b[:active].size, b[:completed].size,
                  Array(lane["epics"]).join(" "))
    end
    puts "\nArchive (unmapped) tickets: #{routed["archive"][:pending].size + routed["archive"][:active].size}"
    puts "Epic map entries: #{epic_map.size}"
  end
end

config = Shard.lanes_config
board = Shard.global_board
routed = Shard.route(board["tickets"] || {}, Shard.epic_map(config))

if ARGV.include?("--charters")
  changed = Shard.write(config, routed, charters: true)
  puts changed.empty? ? "No shard changes." : "Wrote:\n  #{changed.join("\n  ")}"
elsif ARGV.include?("--write")
  changed = Shard.write(config, routed)
  puts changed.empty? ? "No shard changes." : "Wrote:\n  #{changed.join("\n  ")}"
elsif ARGV.include?("--check")
  errors = Shard.validate(config, routed)
  if errors.empty?
    puts "Lane registry + board shards OK (#{config["lanes"].size} lanes)."
    exit 0
  else
    warn "Lane validation FAILED:"
    errors.each { |e| warn "  - #{e}" }
    exit 1
  end
else
  Shard.report(config, routed)
  puts "\nRun with --write to seed lane boards; --check to validate; --charters to (re)generate charters."
end
