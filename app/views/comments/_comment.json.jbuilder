json.extract! comment, :id, :content, :user_id, :quote_id, :parent_id, :created_at, :updated_at
json.user_email comment.user.email
json.user_name comment.user.email.split("@").first.capitalize
json.formatted_content simple_format(h(comment.content))
json.time_ago time_ago_in_words(comment.created_at)
json.can_delete (current_user.admin? || current_user == comment.user)

if comment.replies.any?
  json.replies comment.replies do |reply|
    json.partial! "comments/comment", comment: reply
  end
end
