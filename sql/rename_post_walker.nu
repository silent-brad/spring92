#!/usr/bin/env nu

# Rename post.walker_id → post.walker for NORM FK model reference.
# Run this BEFORE starting the app after the NORM migration.
#
# Usage: nu sql/rename_post_walker.nu

def main [] {
  let db = "spring92.db"

  if not ($db | path exists) {
    error make { msg: $"Database not found at ($db)" }
  }

  let columns = (sqlite3 $db "PRAGMA table_info(post)" | lines | each { $in | split column "|" } | flatten | rename cid name type notnull dflt pk)

  if ($columns | where name == "walker_id" | length) > 0 {
    print "Renaming post.walker_id → post.walker..."
    sqlite3 $db "ALTER TABLE post RENAME COLUMN walker_id TO walker"
    print "  done"
  } else if ($columns | where name == "walker" | length) > 0 {
    print "Column already named 'walker', nothing to do."
  } else {
    error make { msg: "Neither 'walker_id' nor 'walker' column found in post table" }
  }

  print "\nMigration complete!"
}
