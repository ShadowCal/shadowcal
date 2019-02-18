# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :remote_accounts, dependent: :destroy
  has_many :sync_pairs, dependent: :destroy
  has_many :calendars, through: :remote_accounts
  has_many :events, through: :calendars

  def self.find_or_create_from_omniauth(access_token)
    data = access_token.info

    User.where(email: data["email"]).first_or_create do |user|
      user.password = Devise.friendly_token[0, 20]
    end
  end

  def calendars?
    remote_accounts.all? { |acc| acc.calendars.any? }
  end

  # is like user.sync_pairs.build but provides default values for to and from
  # calendars, based on the user's remote accounts
  def default_sync_pair
    default_calendars = remote_accounts.first(2).map{ |a| a.default_calendar&.id }.compact

    SyncPair.new from_calendar_id: default_calendars.shift, to_calendar_id: default_calendars.shift
  end

  def add_or_update_remote_account(access_token, type)
    data = access_token.info

    refresh_token = access_token.credentials.refresh_token
    token_expires_at = nil

    unless refresh_token.blank?
      token_expires_at = access_token.credentials.expires_at || 40.minutes.from_now
    end

    remote_accounts .where(email: data["email"], type: type)
                    .first_or_initialize
                    .update_attributes!(
                      access_token: access_token.credentials.token,
                      token_secret: access_token.credentials.secret,
                      token_expires_at: token_expires_at,
                      refresh_token: refresh_token
                    )
  end

  def access_token
    Rails.logger.warn "Deprecated: Don't ask for user.access_token. Tokens come from accounts"

    remote_accounts.first.try(:access_token)
  end
end
