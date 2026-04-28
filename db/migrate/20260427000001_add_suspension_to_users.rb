class AddSuspensionToUsers < ActiveRecord::Migration[8.1]
  # Adds first-class suspension fields to `users` so suspension applies uniformly
  # across roles (worker / employer / admin), instead of only being modeled on
  # `employer_profiles.suspended_at`.
  #
  # Backfill: copies `employer_profiles.suspended_at` onto the corresponding
  # `users.suspended_at` for existing suspended employers. We intentionally do
  # NOT backfill `suspension_reason`: the closest column on employer_profiles is
  # `verification_notes`, which is reused across approve/reject/request-info
  # flows and is not specifically a suspension reason. Leaving it nil avoids
  # surfacing misleading data.
  #
  # `employer_profiles.suspended_at` is NOT dropped here — it remains for
  # backward compatibility while callers migrate to `users.suspended_at`.
  def up
    add_column :users, :suspended_at, :datetime
    add_column :users, :suspension_reason, :text
    add_column :users, :suspended_by_id, :uuid

    add_index :users, :suspended_at
    add_index :users, :suspended_by_id
    add_foreign_key :users, :users, column: :suspended_by_id

    execute <<~SQL.squish
      UPDATE users
      SET suspended_at = ep.suspended_at
      FROM employer_profiles ep
      WHERE ep.user_id = users.id
        AND ep.suspended_at IS NOT NULL
        AND users.role = 'employer'
    SQL
  end

  def down
    remove_foreign_key :users, column: :suspended_by_id
    remove_index :users, :suspended_by_id
    remove_index :users, :suspended_at
    remove_column :users, :suspended_by_id
    remove_column :users, :suspension_reason
    remove_column :users, :suspended_at
  end
end
