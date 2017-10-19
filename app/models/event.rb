class Event < ActiveRecord::Base
  belongs_to :calendar
  belongs_to :source_event, foreign_key: :source_event_id, class_name: 'Event'
  has_one :shadow_event, foreign_key: :source_event_id, class_name: 'Event'
end
