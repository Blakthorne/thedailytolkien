# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_06_173758) do
  create_table "activity_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "action"
    t.string "target_type"
    t.integer "target_id"
    t.text "details"
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "quote_id", null: false
    t.integer "parent_id"
    t.text "content", null: false
    t.integer "depth", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "edited_at"
    t.text "original_content"
    t.integer "edit_count"
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["depth"], name: "index_comments_on_depth"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["quote_id"], name: "index_comments_on_quote_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "quote_likes", force: :cascade do |t|
    t.integer "user_id"
    t.integer "quote_id", null: false
    t.integer "like_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["like_type"], name: "index_quote_likes_on_like_type"
    t.index ["quote_id"], name: "index_quote_likes_on_quote_id"
    t.index ["user_id", "quote_id"], name: "index_quote_likes_on_user_id_and_quote_id", unique: true
    t.index ["user_id"], name: "index_quote_likes_on_user_id"
  end

  create_table "quote_tags", force: :cascade do |t|
    t.integer "quote_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quote_id", "tag_id"], name: "index_quote_tags_on_quote_id_and_tag_id", unique: true
    t.index ["quote_id"], name: "index_quote_tags_on_quote_id"
    t.index ["tag_id"], name: "index_quote_tags_on_tag_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.string "text"
    t.string "book"
    t.string "chapter"
    t.string "context"
    t.string "character"
    t.integer "days_displayed"
    t.integer "last_date_displayed"
    t.integer "first_date_displayed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "dislikes_count", default: 0, null: false
    t.integer "comments_count", default: 0, null: false
    t.index ["book", "character"], name: "index_quotes_on_book_and_character"
    t.index ["book"], name: "index_quotes_on_book"
    t.index ["character"], name: "index_quotes_on_character"
    t.index ["comments_count"], name: "index_quotes_on_comments_count"
    t.index ["dislikes_count"], name: "index_quotes_on_dislikes_count"
    t.index ["first_date_displayed"], name: "index_quotes_on_first_date_displayed"
    t.index ["last_date_displayed", "created_at"], name: "index_quotes_on_last_date_created_at"
    t.index ["last_date_displayed"], name: "index_quotes_on_last_date_displayed"
    t.index ["likes_count"], name: "index_quotes_on_likes_count"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "role", default: "commentor", null: false
    t.string "name"
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sign_in_count"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "current_streak", default: 0, null: false
    t.integer "longest_streak", default: 0, null: false
    t.date "last_login_date"
    t.string "streak_timezone", default: "UTC", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["current_streak"], name: "index_users_on_current_streak"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_login_date"], name: "index_users_on_last_login_date"
    t.index ["longest_streak"], name: "index_users_on_longest_streak"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["streak_timezone"], name: "index_users_on_streak_timezone"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "activity_logs", "users"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "quotes"
  add_foreign_key "comments", "users", on_delete: :nullify
  add_foreign_key "quote_likes", "quotes"
  add_foreign_key "quote_likes", "users", on_delete: :nullify
  add_foreign_key "quote_tags", "quotes"
  add_foreign_key "quote_tags", "tags"
end
