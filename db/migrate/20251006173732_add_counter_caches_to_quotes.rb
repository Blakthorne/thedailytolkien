class AddCounterCachesToQuotes < ActiveRecord::Migration[8.0]
  def up
    # Add counter cache columns with defaults
    add_column :quotes, :likes_count, :integer, default: 0, null: false
    add_column :quotes, :dislikes_count, :integer, default: 0, null: false
    add_column :quotes, :comments_count, :integer, default: 0, null: false

    # Add indexes for efficient sorting and filtering
    add_index :quotes, :likes_count
    add_index :quotes, :dislikes_count
    add_index :quotes, :comments_count

    # Backfill existing data
    say_with_time "Backfilling counter caches for existing quotes..." do
      Quote.find_each do |quote|
        # Manually count all associations since we're using manual counter caches
        comments_count = quote.comments.count
        likes_count = quote.quote_likes.where(like_type: 1).count
        dislikes_count = quote.quote_likes.where(like_type: 0).count

        quote.update_columns(
          comments_count: comments_count,
          likes_count: likes_count,
          dislikes_count: dislikes_count
        )
      end
    end
  end

  def down
    remove_index :quotes, :comments_count
    remove_index :quotes, :dislikes_count
    remove_index :quotes, :likes_count

    remove_column :quotes, :comments_count
    remove_column :quotes, :dislikes_count
    remove_column :quotes, :likes_count
  end
end
