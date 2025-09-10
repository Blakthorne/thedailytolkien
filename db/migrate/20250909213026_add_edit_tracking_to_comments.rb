class AddEditTrackingToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :edited_at, :datetime
    add_column :comments, :original_content, :text
    add_column :comments, :edit_count, :integer
  end
end
