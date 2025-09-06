class CreateQuotes < ActiveRecord::Migration[8.0]
  def change
    create_table :quotes do |t|
      t.string :text
      t.string :book
      t.string :chapter
      t.string :context
      t.string :character
      t.integer :days_displayed
      t.integer :last_date_displayed
      t.integer :first_date_displayed

      t.timestamps
    end
  end
end
