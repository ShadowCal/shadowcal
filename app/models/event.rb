class Event < ActiveRecord::Base
  belongs_to :calendar
  belongs_to :source_event, foreign_key: :source_event_id, class_name: 'Event'
  has_one :shadow_event, foreign_key: :source_event_id, class_name: 'Event'

  scope :without_shadows, -> {
    joins('LEFT JOIN events as e2 on events.id = e2.source_event_id')
    .where('e2.source_event_id IS NULL')
  }

  def description
    if not source_event_id.blank?
      "Details of this event are private, visible only to you. \n\nSourceEvent##{source_event_id}"
    else
      super
    end
  end
end
