class AllowCommentsWithoutUsers < ActiveRecord::Migration[8.0]
  def change
    # Remove the foreign key constraint
    remove_foreign_key :comments, :users

    # Allow user_id to be null
    change_column_null :comments, :user_id, true

    # Add foreign key back without the constraint that prevents nullification
    add_foreign_key :comments, :users, on_delete: :nullify
  end
end
