class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quote, null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :comments }
      t.text :content, null: false
      t.integer :depth, null: false, default: 0

      t.timestamps
    end

    # Add indexes for performance
    add_index :comments, :depth
    add_index :comments, :created_at
  end
end
