# frozen_string_literal: true

class SyncPair < ActiveRecord::Base
  belongs_to :user

  belongs_to :to_calendar, class_name: "Calendar", foreign_key: "to_calendar_id"
  belongs_to :from_calendar, class_name: "Calendar", foreign_key: "from_calendar_id"

  validates :to_calendar, :from_calendar, presence: true

  after_create :perform_sync, unless: :skip_callbacks

  def perform_sync
    CalendarShadowHelper.cast_from_to(from_calendar, to_calendar)
    update_attributes! last_synced_at: Time.current
  end
end
