class AddDiscoverIndexesToQuotes < ActiveRecord::Migration[8.0]
  def change
    # Add index on last_date_displayed for date-based queries in discover
    add_index :quotes, :last_date_displayed, name: 'index_quotes_on_last_date_displayed'

    # Add index on first_date_displayed for historical range queries
    add_index :quotes, :first_date_displayed, name: 'index_quotes_on_first_date_displayed'

    # Add composite index on (last_date_displayed, created_at) for discover sorting
    add_index :quotes, [ :last_date_displayed, :created_at ], name: 'index_quotes_on_last_date_created_at'
  end
end
