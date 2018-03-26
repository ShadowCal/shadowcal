# frozen_string_literal: true

module DescriptionTagHelper
  PREFIX = "\n\n\n\nSourceEvent#"

  def add_source_event_id_tag_to_description(source_event_id, description)
    [description, PREFIX, source_event_id].join
  end

  def extract_source_event_id_tag_from_description(description)
    description.try(:[], /SourceEvent#([0-9]+)/, 1).try(:to_i)
  end

  extend self
end
