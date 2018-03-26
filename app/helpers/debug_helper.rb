# frozen_string_literal: true

module DebugHelper
  def identify_event(event)
    if event.start_at.nil?
      pacific_start_str = "[NO START DATE]"
    else
      pacific_start_str = event.start_at
           .in_time_zone("Pacific Time (US & Canada)")
           .strftime("%-d/%-m/%y: %H:%M %Z")
    end

    event_id_str = event.new_record? ? "new" : "##{event.id}"

    name_str = event.source_event_id? ? "(Shadow of \"#{event.source_event.try(:name) || '[SOURCE EVENT NOT FOUND]'}\"##{event.source_event_id})" : "\"#{event.name}\""

    [name_str, "(#{event_id_str})", "(#{pacific_start_str})"].join "\t"
  end

  extend self
end
