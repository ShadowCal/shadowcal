class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :google_accounts
  has_many :sync_pairs

  def self.from_omniauth(access_token)
      data = access_token.info

      user = User.where(:email => data["email"]).first

      unless user
          user = User.create(name: data["name"],
             email: data["email"],
             password: Devise.friendly_token[0,20]
          )
      end

      user.google_accounts.where{email==my{data["email"]}}
        .first_or_create
        .update_attributes!({
          access_token: access_token.credentials.token,
          token_secret: access_token.credentials.secret,
          token_expires: access_token.credentials.expires_at,
        })

      user
  end

  def access_token
    google_accounts.first.try(:access_token)
  end

end
