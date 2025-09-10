class CreateQuoteLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :quote_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quote, null: false, foreign_key: true
      t.integer :like_type, null: false

      t.timestamps
    end

    # Ensure a user can only have one like per quote
    add_index :quote_likes, [ :user_id, :quote_id ], unique: true
    add_index :quote_likes, :like_type
  end
end
