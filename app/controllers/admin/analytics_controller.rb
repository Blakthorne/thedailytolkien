class Admin::AnalyticsController < AdminController
  def index
    @analytics = calculate_analytics
    @chart_data = prepare_chart_data

    # No logging for analytics views
  end

  private

  def calculate_analytics
    {
      quotes: {
        total: Quote.count,
        this_month: Quote.where("created_at > ?", 1.month.ago).count,
        this_week: Quote.where("created_at > ?", 1.week.ago).count,
        today: Quote.where("created_at > ?", Date.current).count,
        by_book: Quote.group(:book).count,
        average_length: Quote.average("LENGTH(text)")&.round(1) || 0
      },
      users: {
        total: User.count,
        admins: User.admin.count,
        commentors: User.commentor.count,
        this_month: User.where("created_at > ?", 1.month.ago).count,
        this_week: User.where("created_at > ?", 1.week.ago).count,
        today: User.where("created_at > ?", Date.current).count,
        by_provider: User.group(:provider).count
      },
      activity: {
        total_activities: ActivityLog.count,
        last_24h: ActivityLog.where("created_at > ?", 24.hours.ago).count,
        last_week: ActivityLog.where("created_at > ?", 1.week.ago).count,
        by_action: ActivityLog.group(:action).count.sort_by { |k, v| -v }.first(10),
        recent_admin_actions: ActivityLog.joins(:user)
                                        .where(users: { role: "admin" })
                                        .where("activity_logs.created_at > ?", 1.week.ago)
                                        .count
      },
      engagement: {
        total_likes: QuoteLike.where(like_type: "like").count,
        total_dislikes: QuoteLike.where(like_type: "dislike").count,
        total_comments: Comment.count,
        top_liked_quotes: Quote.joins(:quote_likes)
                              .where(quote_likes: { like_type: "like" })
                              .group("quotes.id", "quotes.text", "quotes.character")
                              .order("COUNT(quote_likes.id) DESC")
                              .limit(10)
                              .count
                              .map { |key, count| { quote: key[1], character: key[2], likes: count } },
        most_commented_quotes: Quote.joins(:comments)
                                   .group("quotes.id", "quotes.text", "quotes.character")
                                   .order("COUNT(comments.id) DESC")
                                   .limit(10)
                                   .count
                                   .map { |key, count| { quote: key[1], character: key[2], comments: count } },
        engagement_by_day: calculate_engagement_by_day
      },
      tags: {
        total_tags: Tag.count,
        most_used_tags: Tag.joins(:quotes)
                          .group("tags.id", "tags.name")
                          .order("COUNT(quotes.id) DESC")
                          .limit(10)
                          .count
                          .map { |key, count| { name: key[1], usage_count: count } },
        untagged_quotes: Quote.left_joins(:quote_tags).where(quote_tags: { id: nil }).count,
        average_tags_per_quote: QuoteTag.count.to_f / Quote.count
      }
    }
  end

  def prepare_chart_data
    # Prepare data for the last 30 days
    dates = (30.days.ago.to_date..Date.current).to_a

    quotes_by_day = Quote.where("created_at > ?", 30.days.ago)
                         .group("DATE(created_at)")
                         .count

    users_by_day = User.where("created_at > ?", 30.days.ago)
                       .group("DATE(created_at)")
                       .count

    activities_by_day = ActivityLog.where("created_at > ?", 30.days.ago)
                                  .group("DATE(created_at)")
                                  .count

    {
      dates: dates.map(&:to_s),
      quotes: dates.map { |date| quotes_by_day[date.to_s] || 0 },
      users: dates.map { |date| users_by_day[date.to_s] || 0 },
      activities: dates.map { |date| activities_by_day[date.to_s] || 0 }
    }
  end

  def calculate_engagement_by_day
    dates = (30.days.ago.to_date..Date.current).to_a

    likes_by_day = QuoteLike.where(like_type: "like")
                           .where("created_at > ?", 30.days.ago)
                           .group("DATE(created_at)")
                           .count

    comments_by_day = Comment.where("created_at > ?", 30.days.ago)
                            .group("DATE(created_at)")
                            .count

    {
      dates: dates.map(&:to_s),
      likes: dates.map { |date| likes_by_day[date.to_s] || 0 },
      comments: dates.map { |date| comments_by_day[date.to_s] || 0 }
    }
  end
end
