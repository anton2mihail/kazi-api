class CreateOtpChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_challenges, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.string :phone, null: false
      t.string :purpose, null: false
      t.string :requested_role
      t.string :code_digest, null: false
      t.integer :attempts_count, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :consumed_at

      t.timestamps
    end

    add_index :otp_challenges, [:phone, :purpose, :expires_at]
    add_index :otp_challenges, :consumed_at
  end
end
