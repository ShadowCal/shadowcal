# frozen_string_literal: true

class Calendar < ActiveRecord::Base
  belongs_to :google_account
  has_many :events, dependent: :destroy

  delegate :access_token, :email, :user, to: :google_account
end
