# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :google_accounts, dependent: :destroy
  has_many :sync_pairs, dependent: :destroy
  has_many :calendars, through: :google_accounts
  has_many :events, through: :calendars

  def self.find_or_create_from_omniauth(access_token)
    data = access_token.info

    User.where(email: data["email"]).first_or_create do |user|
      user.password = Devise.friendly_token[0, 20]
    end
  end

  def calendars?
    google_accounts.all? { |acc| acc.calendars.any? }
  end

  def add_or_update_google_account(access_token)
    data = access_token.info

    refresh_token = access_token.credentials.refresh_token
    token_expires_at = access_token.credentials.expires_at || 40.minutes.from_now unless refresh_token.blank?

    google_accounts.where(email: data["email"])
                   .first_or_create
                   .update_attributes!(access_token:     access_token.credentials.token,
                                       token_secret:     access_token.credentials.secret,
                                       token_expires_at: token_expires_at,
                                       refresh_token:    refresh_token)
  end

  def access_token
    google_accounts.first.try(:access_token)
  end
end
