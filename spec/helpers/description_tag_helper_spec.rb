# frozen_string_literal: true

require "rails_helper"


describe DescriptionTagHelper do
  let(:description) { Faker::Lorem.sentence }
  let(:source_event_id) { 123 }

  describe "#add_source_event_id_tag_to_description" do
    let(:result) { subject.add_source_event_id_tag_to_description(source_event_id, description) }
    it "appends the tag" do
      expect(result).to end_with(source_event_id.to_s)
      expect(result).to start_with(description)
    end
  end

  describe "#extract_source_event_id_tag_from_description" do
    let(:result) { subject.extract_source_event_id_tag_from_description(description + subject::PREFIX + source_event_id.to_s) }
    it "extracts the id" do
      expect(result).to eq source_event_id
    end
  end

  describe "both together" do
    it "convert symmetrically" do
      tagged_description = subject.add_source_event_id_tag_to_description(source_event_id, description)
      extracted_source_event_id = subject.extract_source_event_id_tag_from_description(tagged_description)
      expect(extracted_source_event_id).to eq source_event_id
    end
  end
end
