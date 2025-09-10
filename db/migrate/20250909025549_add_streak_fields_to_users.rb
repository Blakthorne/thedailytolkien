class AddStreakFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :current_streak, :integer, default: 0, null: false
    add_column :users, :longest_streak, :integer, default: 0, null: false
    add_column :users, :last_login_date, :date
    add_column :users, :streak_timezone, :string, default: 'UTC', null: false

    # Add indexes for performance
    add_index :users, :current_streak
    add_index :users, :longest_streak
    add_index :users, :last_login_date
    add_index :users, :streak_timezone
  end
end
