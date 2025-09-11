class AllowQuoteLikesWithoutUsers < ActiveRecord::Migration[8.0]
  def change
    # Remove the existing foreign key constraint
    remove_foreign_key :quote_likes, :users

    # Remove the unique index that includes user_id
    remove_index :quote_likes, name: "index_quote_likes_on_user_id_and_quote_id"

    # Allow user_id to be null
    change_column_null :quote_likes, :user_id, true

    # Add foreign key back with nullify on delete
    add_foreign_key :quote_likes, :users, on_delete: :nullify

    # Add a new unique index that allows null user_id but prevents duplicates for non-null user_id
    # Note: SQLite treats NULL values as distinct, so this will work correctly
    add_index :quote_likes, [ :user_id, :quote_id ], unique: true, name: "index_quote_likes_on_user_id_and_quote_id"
  end
end
