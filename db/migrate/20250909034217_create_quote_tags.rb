class CreateQuoteTags < ActiveRecord::Migration[8.0]
  def change
    create_table :quote_tags do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    # Ensure unique quote-tag combinations
    add_index :quote_tags, [ :quote_id, :tag_id ], unique: true
  end
end
