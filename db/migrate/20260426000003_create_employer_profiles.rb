class CreateEmployerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :employer_profiles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.string :company_name
      t.string :contact_name
      t.string :company_size
      t.string :industry_type
      t.string :website
      t.text :description
      t.string :city
      t.string :service_areas, array: true, null: false, default: []
      t.string :benefits, array: true, null: false, default: []
      t.boolean :verified, null: false, default: false

      t.timestamps
    end

    add_index :employer_profiles, :verified
    add_index :employer_profiles, :company_name
  end
end
