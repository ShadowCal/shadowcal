# frozen_string_literal: true

class Event < ActiveRecord::Base
  belongs_to :calendar
  belongs_to :source_event, foreign_key: :source_event_id, class_name: "Event"
  has_one :shadow_event, foreign_key: :source_event_id, class_name: "Event", dependent: :nullify

  scope :attending, lambda {
    # Fully qualified table name to prevent "ambuous column" when also joining to self
    where("events.is_attending = ?", true)
  }

  scope :blocking, lambda {
    # Fully qualified table name to prevent "ambuous column" when also joining to self
    where("events.is_blocking = ?", true)
  }

  scope :without_shadows, lambda {
    joins("LEFT JOIN events as e2 on events.id = e2.source_event_id")
      .where("e2.source_event_id IS NULL")
  }

  has_one :remote_account, through: :calendar
  has_one :user, through: :remote_account
  delegate :access_token, to: :remote_account

  before_save :push_date_changes_to_corresponding_event, if: :moved?
  before_save :toggle_shadow, if: :should_toggle_shadow?

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

  def outside_work_hours
    local_start_at = start_at.in_time_zone(calendar.time_zone)
    local_end_at = end_at.in_time_zone(calendar.time_zone)

    log "local_start_at: #{local_start_at.inspect}"
    log "local_end_at: #{local_end_at.inspect}"

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

    log "Start and end on weekend?"

    return true if start_weekend && end_weekend && (end_day - start_day < 2.day)

    log "Start and end before workday?"

    return true if start_hour < 8 && end_hour < 8 && same_day

    log "Start and end after workday?"

    return true if start_hour >= 19 && end_hour >= 19 && same_day

    log "End after and start before workday?"

    return true if start_hour >= 19 && end_hour < 8 && (end_day - start_day == 1.day)

    log "Nope, its during work hours!"

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
        end_at,
        is_all_day
      )

    Event
      .where(id: corresponding_event.id)
      .update_all(start_at: start_at, end_at: end_at)
  end

  def should_have_shadow?
    is_attending == true && is_blocking == true && source_event_id.nil?
  end

  def should_toggle_shadow?
    (should_have_shadow? && !shadow?) ||
      (shadow? && !should_have_shadow?)
  end

  def shadow?
    !shadow_event&.external_id.nil?
  end

  def toggle_shadow
    return true if skip_callbacks

    if new_record?
      log "Event is being imported. Ignoring toggle_shadow because sync importer will create in bulk"
      return true
    end

    if shadow?
      log "Event is itself a shadow, ignoring."
      return true
    end

    if outside_work_hours
      log "Event is outside work hours. Ignoring"
      return true
    end

    if corresponding_calendar.nil?
      log "Calendar to which event belongs is not casting a shadow. Aborting."
      return true
    end

    begin
      log "Shadow Exists?", shadow?.inspect
      log "Shadow Should Exist?", should_have_shadow?.inspect

      if shadow? && !should_have_shadow?
        log(
          "No longer attending this event. Removing shadow from external calendar",
          shadow_event.calendar.external_id,
          shadow_event.external_id
        )

        transaction do
          Event
            .where(id: shadow_event.id)
            .destroy_all

          CalendarShadowHelper.destroy_shadow_of_event(self)
        end
      elsif !shadow? && should_have_shadow?
        log "Now attending this event. Creating remote shadow..."

        CalendarShadowHelper.push_shadow_of_event(self)
      end
    rescue CalendarShadowHelper::ShadowHelperError => e
      log "Calendar Error: ", e
      raise
    end

    true
  end
end
