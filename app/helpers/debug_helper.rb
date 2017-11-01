
module DebugHelper
	def identify_event(event)
		pacific_start_str = event.start_at
			.in_time_zone("Pacific Time (US & Canada)")
			.strftime("%-d/%-m/%y: %H:%M %Z")

		event_id_str = event.new_record? ? "new" : "##{event.id}"

		name_str = event.source_event_id? ? "(Shadow of \"#{event.source_event.name}\"##{event.source_event_id})" : "\"#{event.name}\""

		[name_str, "(#{event_id_str})", "(#{pacific_start_str})"].join "\t"
	end

	extend self
end