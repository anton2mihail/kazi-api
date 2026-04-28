# Rebuilds the indexes added by 20260427000001_add_suspension_to_users using
# PostgreSQL's CREATE INDEX CONCURRENTLY so the build does not lock writes on
# the `users` table during production deploys.
#
# This lives in a separate migration because `algorithm: :concurrently` cannot
# run inside a DDL transaction, and column-add migrations must remain
# transactional. Keeping the concurrent reindex isolated lets us call
# `disable_ddl_transaction!` only here.
#
# The migration is idempotent: each step checks `index_exists?` before acting,
# so it is safe to re-run (e.g. if a prior attempt failed midway and left an
# INVALID index behind).
class ReindexUsersSuspensionConcurrently < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    if index_exists?(:users, :suspended_at)
      remove_index :users, :suspended_at, algorithm: :concurrently
    end
    unless index_exists?(:users, :suspended_at)
      add_index :users, :suspended_at, algorithm: :concurrently
    end

    if index_exists?(:users, :suspended_by_id)
      remove_index :users, :suspended_by_id, algorithm: :concurrently
    end
    unless index_exists?(:users, :suspended_by_id)
      add_index :users, :suspended_by_id, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:users, :suspended_at)
      remove_index :users, :suspended_at, algorithm: :concurrently
    end
    if index_exists?(:users, :suspended_by_id)
      remove_index :users, :suspended_by_id, algorithm: :concurrently
    end

    add_index :users, :suspended_at unless index_exists?(:users, :suspended_at)
    add_index :users, :suspended_by_id unless index_exists?(:users, :suspended_by_id)
  end
end
