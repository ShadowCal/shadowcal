# frozen_string_literal: true

class Event < ActiveRecord::Base
  belongs_to :calendar
  belongs_to :source_event, foreign_key: :source_event_id, class_name: "Event"
  has_one :shadow_event, foreign_key: :source_event_id, class_name: "Event", dependent: :nullify

  scope :without_shadows, lambda {
    joins("LEFT JOIN events as e2 on events.id = e2.source_event_id")
      .where("e2.source_event_id IS NULL")
  }

  has_one :google_account, through: :calendar
  delegate :access_token, to: :google_account

  before_save :push_changes_to_corresponding_event, if: :moved?

  def moved?
    return false if new_record?
    return true if start_at_changed?
    return true if end_at_changed?
  end

  def corresponding_event
    source_event || shadow_event
  end

  private

  def push_changes_to_corresponding_event
    Rails.logger.debug [DebugHelper.identify_event(self), "Saving after being moved. Corresponding event?"].join "\t"

    if corresponding_event.nil?
      Rails.logger.debug [DebugHelper.identify_event(self), "No corresponding event to move"].join "\t"
      return true
    end

    Rails.logger.debug [DebugHelper.identify_event(self), "Moving corresponding event:", DebugHelper.identify_event(corresponding_event)].join "\t"

    GoogleCalendarApiHelper
      .move_event(
        corresponding_event.access_token,
        corresponding_event.calendar.external_id,
        corresponding_event.external_id,
        start_at,
        end_at
      )

    Event
      .where(id: corresponding_event.id)
      .update_all(start_at: start_at, end_at: end_at)
  end
end
