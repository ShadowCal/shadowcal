class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :google_accounts
  has_many :sync_pairs
  has_many :calendars, through: :google_accounts

  def self.find_or_create_from_omniauth(access_token)
    data = access_token.info

    User.where(:email => data["email"]).first_or_create do |user|
      user.password = Devise.friendly_token[0,20]
    end
  end

  def add_or_update_google_account(access_token)
    data = access_token.info

    self.google_accounts.where(email: data["email"])
      .first_or_create
      .update_attributes!({
        access_token: access_token.credentials.token,
        token_secret: access_token.credentials.secret,
        token_expires: access_token.credentials.expires_at,
      })
  end

  def access_token
    google_accounts.first.try(:access_token)
  end

end
