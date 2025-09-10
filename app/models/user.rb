class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # Validations
  validates :role, inclusion: { in: %w[admin commentor] }
  validates :streak_timezone, presence: true, inclusion: {
    in: ActiveSupport::TimeZone.all.map(&:name),
    message: "must be a valid timezone"
  }
  validates :current_streak, presence: true, numericality: {
    greater_than_or_equal_to: 0, only_integer: true
  }
  validates :longest_streak, presence: true, numericality: {
    greater_than_or_equal_to: 0, only_integer: true
  }

  # Enums
  enum :role, { commentor: "commentor", admin: "admin" }

  # Associations for interaction system
  has_many :quote_likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :activity_logs, dependent: :destroy

  # Callbacks
  before_validation :set_default_role, on: :create
  before_validation :set_default_timezone, on: :create

  # Class methods
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.password = Devise.friendly_token[0, 20]
    end
  end

  # Instance methods
  def admin?
    role == "admin"
  end

  def commentor?
    role == "commentor"
  end

  # Streak-related methods
  def streak_display
    case current_streak
    when 0
      "No streak yet"
    when 1
      "1 day streak!"
    else
      "#{current_streak} day streak!"
    end
  end

  def streak_emoji
    case current_streak
    when 0
      "📅"
    when 1..7
      "🔥"
    when 8..30
      "⚡"
    when 31..99
      "🏆"
    else
      "👑"
    end
  end

  def has_longest_streak_record?
    longest_streak > 0 && longest_streak > current_streak
  end

  def update_login_streak(login_time: Time.current)
    StreakUpdateService.new(self, login_time).call
  end

  def reset_streak!
    update!(
      current_streak: 0,
      last_login_date: nil
    )
  end

  def recalculate_streak!(login_time: Time.current)
    calculator = StreakCalculatorService.new(self, login_time)
    streak_data = calculator.calculate_streak

    update!(
      current_streak: streak_data[:current_streak],
      longest_streak: streak_data[:longest_streak],
      last_login_date: login_time.in_time_zone(streak_timezone).to_date
    )
  end

  private

  def set_default_role
    self.role ||= "commentor"
  end

  def set_default_timezone
    self.streak_timezone ||= "UTC"
  end
end
