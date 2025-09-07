class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.string :target_type
      t.integer :target_id
      t.text :details
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end
  end
end
