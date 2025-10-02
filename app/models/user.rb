class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # Validations
  validates :role, inclusion: { in: %w[admin commentor] }
  validates :first_name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 1, maximum: 50 }
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
  has_many :quote_likes, dependent: :nullify
  has_many :comments, dependent: :nullify
  has_many :activity_logs, dependent: :destroy

  # Callbacks
  before_validation :set_default_role, on: :create
  before_validation :set_default_timezone, on: :create
  after_create :initialize_streak_data

  # Class methods
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email

      # Split the OAuth name into first and last name
      if auth.info.name.present?
        name_parts = auth.info.name.strip.split(" ")
        user.first_name = name_parts.first
        user.last_name = name_parts.length > 1 ? name_parts[1..-1].join(" ") : "User"
      else
        user.first_name = "User"
        user.last_name = "Name"
      end

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

  # Name display methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    "#{first_name} #{last_name.first}."
  end

  # For backward compatibility
  def name
    full_name
  end

  def name=(full_name_string)
    return if full_name_string.blank?

    name_parts = full_name_string.strip.split(" ")
    self.first_name = name_parts.first
    self.last_name = name_parts.length > 1 ? name_parts[1..-1].join(" ") : "User"
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
    # If timezone is blank or invalid, set default
    if streak_timezone.blank?
      self.streak_timezone = "UTC"
    else
      # Convert IANA timezone identifier to Rails timezone name if needed
      converted_timezone = convert_iana_to_rails_timezone(streak_timezone)
      self.streak_timezone = converted_timezone
    end
  end

  def convert_iana_to_rails_timezone(timezone_identifier)
    # Return as-is if it's already a valid Rails timezone name
    return timezone_identifier if ActiveSupport::TimeZone.all.map(&:name).include?(timezone_identifier)

    # Try to find Rails timezone by IANA identifier
    rails_timezone = ActiveSupport::TimeZone.all.find { |tz| tz.tzinfo.identifier == timezone_identifier }

    # Return the Rails name if found, otherwise default to UTC
    rails_timezone ? rails_timezone.name : "UTC"
  end

  def initialize_streak_data
    # Set initial login date to today in the user's timezone
    # This ensures their streak starts correctly from day 1
    today_in_timezone = Time.current.in_time_zone(streak_timezone).to_date
    update_column(:last_login_date, today_in_timezone)
  end
end
