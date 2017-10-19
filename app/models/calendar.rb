class Calendar < ActiveRecord::Base
  belongs_to :google_account
  has_many :events

  delegate :access_token, to: :google_account
end
