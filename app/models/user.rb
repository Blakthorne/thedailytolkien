class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2, :facebook ]

  # Validations
  validates :role, inclusion: { in: %w[admin commentor] }

  # Callbacks
  before_validation :set_default_role, on: :create

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

  private

  def set_default_role
    self.role ||= "commentor"
  end
end
