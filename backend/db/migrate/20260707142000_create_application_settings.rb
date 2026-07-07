class CreateApplicationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :application_settings do |t|
      t.boolean :registration_enabled, null: false, default: true
      t.boolean :email_login_enabled, null: false, default: true
      t.integer :singleton_guard, null: false, default: 0

      t.timestamps
    end

    add_index :application_settings, :singleton_guard, unique: true
  end
end
