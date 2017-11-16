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
  has_one :user, through: :google_account
  delegate :access_token, to: :google_account

  before_save :push_date_changes_to_corresponding_event, if: :moved?
  before_save :toggle_shadow, if: :is_attending_changed?

  def moved?
    return false if new_record?
    return true if start_at_changed?
    return true if end_at_changed?
  end

  def corresponding_event
    source_event || shadow_event
  end

  def corresponding_calendar
    @corresponding_calendar ||= calendar.user.sync_pairs.find{ |pair| pair.from_calendar_id = calendar_id }
  end

  private

  def log(*msg)
    [DebugHelper.identify_event(self), *msg].join("\t").tap{ |msg_str| Rails.logger.debug msg_str }
  end

  def push_date_changes_to_corresponding_event
    log "Saving after being moved. Corresponding event?"

    if corresponding_event.nil?
      log "No corresponding event to move"
      return true
    end

    log "Moving corresponding event:", DebugHelper.identify_event(corresponding_event)

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

  def toggle_shadow
    return true if skip_callbacks
    log "is_attending changed from #{is_attending_was.inspect} => #{is_attending.inspect}"

    # Ignore attendance changes on shadows themselves
    if !source_event_id.nil?
      log "Event is a shadow, ignoring that is_attending changed. Aborting."
      return true
    end

    if corresponding_calendar.nil?
      log "Calendar to which event belongs is not casting a shadow. Aborting."
      return true
    end

    begin
      transaction do
        shadow_exists = !!(shadow_event&.external_id)

        log "Shadow Exists?", shadow_exists.inspect

        if shadow_exists && is_attending == false
          log(
            "No longer attending this event. Removing shadow from external calendar",
            shadow_event.calendar.external_id,
            shadow_event.external_id
          )

          Event
            .where(id: shadow_event.id)
            .destroy_all

          CalendarShadowHelper.destroy_shadow_of_event(self)

        elsif !shadow_exists && is_attending == true
          log "Now attending this event. Creating remote shadow..."

          CalendarShadowHelper.create_shadow_of_event(self)
        end
      end
    rescue CalendarShadowHelper::ShadowHelperError => e
      log "Calendar Error: ", e
    end

    true
  end
end
