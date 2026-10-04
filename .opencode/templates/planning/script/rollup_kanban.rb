#!/usr/bin/env ruby
# frozen_string_literal: true

# rollup_kanban.rb — push lane board shards back up into the global board.
#
# The global docs/planning/kanban_state.json is the rollup/history. Lanes own
# their shards; this merges lane-local LIVE state (pending/active) and ticket
# metadata into the global board, and moves lane-completed slugs out of
# pending/active. Completed HISTORY ordering is left untouched — existing
# completed entries keep their order; only genuinely new completions append.
#
# Direction: lane shard -> global. (script/shard_kanban.rb seeds the other way,
# additively, without clobbering lane edits.)
#
# Usage:
#   ruby script/rollup_kanban.rb                 # dry run (default): show plan
#   ruby script/rollup_kanban.rb --write         # apply to the global board
#   ruby script/rollup_kanban.rb --check         # exit 1 if logically out of sync
#   ruby script/rollup_kanban.rb --global PATH --lanes-dir PATH --config PATH
#
# Idempotent: a second run reports "already in sync".

require "json"
require "set"
require "optparse"

ROOT     = File.expand_path("..", __dir__)
PLANNING = File.join(ROOT, "docs", "planning")
DEFAULTS = {
  config: File.join(PLANNING, "lanes.json"),
  global: File.join(PLANNING, "kanban_state.json"),
  lanes_dir: File.join(PLANNING, "lanes")
}.freeze

COLUMNS = %w[pending active completed].freeze

# lane boards assert: live(slug=>"pending"/"active"), completed(Set), meta(slug=>meta)
def collect(lanes_dir, lane_ids)
  live = {}
  completed = Set.new
  meta = {}
  lane_ids.each do |id|
    path = File.join(lanes_dir, id, "kanban_state.json")
    next unless File.exist?(path)

    board = JSON.parse(File.read(path))
    cols = board["columns"] || {}
    Array(cols["pending"]).each { |slug| live[slug] = "pending" }
    Array(cols["active"]).each { |slug| live[slug] = "active" }
    Array(cols["completed"]).each { |slug| completed << slug }
    (board["tickets"] || {}).each { |slug, m| meta[slug] = m }
  end
  [live, completed, meta]
end

def id_from_slug(slug)
  m = slug.match(/\A(T-BUG-\d+|T-\d+)/)
  m ? m[1] : slug
end

def build_global(global, lane_ids, lanes_dir)
  live, lane_completed, meta = collect(lanes_dir, lane_ids)
  out = Marshal.load(Marshal.dump(global)) # deep copy
  out["columns"] ||= {}
  out["tickets"] ||= {}
  COLUMNS.each { |c| out["columns"][c] ||= [] }

  existing = {}
  COLUMNS.each { |col| Array(out["columns"][col]).each { |slug| existing[slug] = col } }

  # 1. metadata upsert (lane shard owns live slugs it manages)
  meta_changes = meta.count { |slug, m| out["tickets"][slug] != m }
  meta.each { |slug, m| out["tickets"][slug] = m }

  # 2. live status
  live.each do |slug, col|
    out["tickets"][slug] ||= { "id" => id_from_slug(slug), "status" => col }
    out["tickets"][slug]["status"] = col
  end

  # 3. lane-completed slugs: a slug is a genuine completion only if it was in
  #    the global live set before this run (derived history is otherwise ignored).
  live_set = existing.select { |_, col| %w[pending active].include?(col) }.keys.to_set
  moved_to_completed = lane_completed.select { |slug| live_set.include?(slug) }
  moved_to_completed.each do |slug|
    out["tickets"][slug] ||= { "id" => id_from_slug(slug) }
    out["tickets"][slug]["status"] = "completed"
  end

  # 4. rebuild pending/active only; lane wins for live slugs and for slugs the
  #    lane has moved to completed.
  new_pa = { "pending" => [], "active" => [] }
  %w[pending active].each do |col|
    Array(out["columns"][col]).each do |slug|
      next if live.key?(slug) || lane_completed.include?(slug)
      new_pa[col] << slug
    end
  end
  live.each { |slug, col| new_pa[col] << slug }
  new_pa.each_value(&:uniq!)

  # 5. completed: keep global order, drop anything now live, prepend genuine
  #    new completions (newest first). Derived history is never added.
  new_completed = Array(out["columns"]["completed"]).reject { |slug| live.key?(slug) }
  even = new_completed.to_set
  moved_to_completed.each do |slug|
    next if even.include?(slug)
    new_completed.unshift(slug)
    even << slug
  end

  added = []
  (new_pa["pending"] - Array(out["columns"]["pending"])).each { |s| added << "pending:#{s}" }
  (new_pa["active"] - Array(out["columns"]["active"])).each { |s| added << "active:#{s}" }
  (new_completed - Array(out["columns"]["completed"])).each { |s| added << "completed:#{s}" }

  out["columns"]["pending"] = new_pa["pending"]
  out["columns"]["active"] = new_pa["active"]
  out["columns"]["completed"] = new_completed

  moved = live.select { |s, c| existing[s] && existing[s] != c }.map { |s, c| "#{s}:#{existing[s]}->#{c}" }

  changes = {
    added: added,
    moved: moved,
    newly_managed: live.keys - existing.keys,
    metadata: meta_changes
  }
  [out, changes]
end

def serialize(board)
  JSON.pretty_generate(board) + "\n"
end

opts = DEFAULTS.dup
mode = :dry
OptionParser.new do |o|
  o.on("--write") { mode = :write }
  o.on("--check") { mode = :check }
  o.on("--global PATH") { |v| opts[:global] = v }
  o.on("--lanes-dir PATH") { |v| opts[:lanes_dir] = v }
  o.on("--config PATH") { |v| opts[:config] = v }
end.parse!(ARGV)

config = JSON.parse(File.read(opts[:config]))
lane_ids = Array(config["lanes"]).reject { |l| l["status"] == "frozen" }.map { |l| l["id"] }
global = JSON.parse(File.read(opts[:global]))

merged, changes = build_global(global, lane_ids, opts[:lanes_dir])
in_sync = (merged == global)

if mode == :check
  if in_sync
    puts "Global board is in sync with lane shards (#{lane_ids.size} lanes)."
    exit 0
  end
  warn "Global board is OUT OF SYNC with lane shards."
  warn "  #{changes[:added].size} column add(s), #{changes[:moved].size} move(s), " \
       "#{changes[:newly_managed].size} newly-managed slug(s), #{changes[:metadata]} metadata change(s)."
  warn "  Run: ruby script/rollup_kanban.rb --write"
  exit 1
end

if in_sync
  puts "Already in sync — nothing to roll up."
else
  puts "Rollup plan (lane shards -> global):"
  puts "  column adds:       #{changes[:added].size}"
  puts "  status moves:      #{changes[:moved].size}"
  puts "  newly managed:     #{changes[:newly_managed].size}"
  puts "  metadata upserts:  #{changes[:metadata]}"
  changes[:moved].first(20).each { |m| puts "    move  #{m}" }
  changes[:added].first(20).each { |a| puts "    add   #{a}" }
end

if mode == :write
  if in_sync
    puts "Nothing written."
  else
    File.write(opts[:global], serialize(merged))
    puts "Wrote #{opts[:global].sub("#{ROOT}/", "")}."
  end
else
  puts "\n(dry run — pass --write to apply)"
end
