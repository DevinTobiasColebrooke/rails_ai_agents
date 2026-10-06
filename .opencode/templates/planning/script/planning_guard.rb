# frozen_string_literal: true

# PlanningGuard — move uncommitted docs/planning changes out of the way so a
# rebase can run, then put them back.
#
# It NEVER uses `git stash`. `refs/stash` is shared by every worktree in the
# repo, so stashing in one swarm can leak another swarm's work into your tree
# (and a `stash pop` can consume someone else's entry). A swarm's uncommitted
# docs/planning edits are the usual reason a rebase refuses to run — this is the
# safe way to set them aside.
#
# Usage:
#   require_relative "../script/planning_guard"
#   PlanningGuard.with_aside(worktree) do
#     system("git", "-C", worktree, "rebase", "origin/main")
#   end
#
# Only the paths that are actually dirty are backed up and restored, so planning
# updates that arrive from the base branch during the rebase are preserved.

require "fileutils"
require "shellwords"
require "time"

module PlanningGuard
  module_function

  PLANNING_PATH = "docs/planning"

  # Dirty (tracked-modified or untracked) paths under docs/planning.
  def changed_paths(worktree)
    out = `git -C #{Shellwords.escape(worktree)} status --porcelain -- #{PLANNING_PATH} 2>/dev/null`
    out.lines.filter_map do |line|
      path = line[3..].to_s.strip
      next if path.empty?

      path = path.split(" -> ").last if path.include?(" -> ")
      path
    end
  end

  def dirty?(worktree)
    !changed_paths(worktree).empty?
  end

  # Back up the dirty planning paths, reset docs/planning to HEAD, run the block
  # (typically a fetch + rebase), then restore the saved paths — even on error.
  def with_aside(worktree)
    paths = changed_paths(worktree)
    return yield if paths.empty?

    backup = File.join(worktree, "tmp", "planning-aside-#{Time.now.to_i}-#{Process.pid}")
    FileUtils.mkdir_p(backup)
    stash_away(worktree, backup, paths)

    begin
      system("git", "-C", worktree, "checkout", "--", PLANNING_PATH,
             out: File::NULL, err: File::NULL)
      system("git", "-C", worktree, "clean", "-fd", "--", PLANNING_PATH,
             out: File::NULL, err: File::NULL)
      yield
    ensure
      put_back(worktree, backup, paths)
      FileUtils.rm_rf(backup)
    end
  end

  def stash_away(worktree, backup, paths)
    paths.each do |path|
      rel = path.delete_prefix("#{PLANNING_PATH}/")
      src = File.join(worktree, path)
      next unless File.exist?(src)

      dest = File.join(backup, File.dirname(rel))
      FileUtils.mkdir_p(dest)
      FileUtils.cp_r(src, dest)
    end
  end

  def put_back(worktree, backup, paths)
    planning = File.join(worktree, PLANNING_PATH)
    paths.each do |path|
      rel = path.delete_prefix("#{PLANNING_PATH}/")
      src = File.join(backup, rel)
      next unless File.exist?(src)

      dest = File.join(planning, File.dirname(rel))
      FileUtils.mkdir_p(dest)
      FileUtils.cp_r(src, dest) # merges; never removes files brought in by the rebase
    end
  end
end
