# frozen_string_literal: true

class Event < ActiveRecord::Base
  belongs_to :calendar
  belongs_to :source_event, foreign_key: :source_event_id, class_name: "Event"
  has_one :shadow_event, foreign_key: :source_event_id, class_name: "Event", dependent: :nullify

  scope :attending, lambda {
    # Fully qualified table name to prevent "ambuous column" when also joining to self
    where("events.is_attending = ?", true)
  }

  scope :busy, lambda {
    # Fully qualified table name to prevent "ambuous column" when also joining to self
    where("events.is_busy = ?", true)
  }


  scope :without_shadows, lambda {
    joins("LEFT JOIN events as e2 on events.id = e2.source_event_id")
      .where("e2.source_event_id IS NULL")
  }

  has_one :remote_account, through: :calendar
  has_one :user, through: :remote_account
  delegate :access_token, to: :remote_account

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
    # Not just corresponding_event&.calendar because it really depends on the
    # calendar/sync-pair status, rather than just is there an event which
    # links to it as the source (of which there may be more than one... )
    calendar.remote_account.user.reload

    sp = calendar.remote_account.user.sync_pairs.find do |pair|
      pair.from_calendar == calendar || pair.to_calendar == calendar
    end

    return nil if sp.nil?

    sp.to_calendar == calendar ? sp.from_calendar : sp.to_calendar
  end

  def description
    if source_event_id.blank?
      ""
    else
      DescriptionTagHelper.add_source_event_id_tag_to_description(
        id,
        "The calendar owner is busy at this time with a private event.\n\n" \
        "This notice was created using shadowcal.com: Block personal events " \
        "off your work calendar without sharing details."
      )
    end
  end

  def outside_work_hours
    local_start_at = start_at.in_time_zone(calendar.time_zone)
    local_end_at = end_at.in_time_zone(calendar.time_zone)

    start_hour = local_start_at.hour
    end_hour = local_end_at.hour
    same_day = local_end_at - local_start_at < 1.day
    start_day = local_start_at.beginning_of_day
    end_day = local_end_at.beginning_of_day

    start_weekend = local_start_at.saturday? ||
                    local_start_at.sunday? ||
                    (local_start_at.friday? && start_hour >= 19) ||
                    (local_start_at.monday? && start_hour < 8)

    end_weekend = local_end_at.saturday? ||
                  local_end_at.sunday? ||
                  (local_end_at.friday? && end_hour >= 19) ||
                  (local_end_at.monday? && end_hour < 8)

    return true if start_weekend && end_weekend && (end_day - start_day < 2.day)

    return true if start_hour < 8 && end_hour < 8 && same_day

    return true if start_hour >= 19 && end_hour >= 19 && same_day

    return true if start_hour >= 19 && end_hour < 8 && (end_day - start_day == 1.day)

    false
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

    corresponding_calendar
      .move_event(
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

          CalendarShadowHelper.push_shadow_of_event(self)
        end
      end
    rescue CalendarShadowHelper::ShadowHelperError => e
      log "Calendar Error: ", e
    end

    true
  end
end
