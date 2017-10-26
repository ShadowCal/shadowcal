# frozen_string_literal: true

class Event < ActiveRecord::Base
  belongs_to :calendar
  belongs_to :source_event, foreign_key: :source_event_id, class_name: "Event"
  has_one :shadow_event, foreign_key: :source_event_id, class_name: "Event", dependent: :nullify

  scope :without_shadows, lambda {
    joins("LEFT JOIN events as e2 on events.id = e2.source_event_id")
      .where("e2.source_event_id IS NULL")
  }

  before_save :push_changes_to_corresponding_event, if: :moved?

  def moved?
    return false if new_record?
    return true if start_at_changed?
    return true if end_at_changed?
  end

  private

  def push_changes_to_corresponding_event; end
end
