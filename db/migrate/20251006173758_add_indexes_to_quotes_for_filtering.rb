class AddIndexesToQuotesForFiltering < ActiveRecord::Migration[8.0]
  def change
    # Add indexes for frequently filtered columns in discover page
    add_index :quotes, :book
    add_index :quotes, :character

    # Composite index for common filter combinations
    add_index :quotes, [ :book, :character ]
  end
end
