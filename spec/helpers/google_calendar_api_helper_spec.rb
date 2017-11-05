# frozen_string_literal: true

require "rails_helper"
require "ostruct"


describe GoogleCalendarApiHelper do
  describe "#service_event_item_to_event_model" do
    let!(:existing_event) { create :event }
    let!(:item) {
      {
        id: existing_event.external_id,
        start: {
          date: Date.today
        },
        end: {
          date: Date.today + 1.day
        },
        summary: Faker::Lorem.sentence,
        description: "",
      }.to_ostruct
    }

    def item_with()
      item.tap(&Proc.new)
    end

    def subject_with_item()
      subject.send(
        :service_event_item_to_event_model,
        item_with(&Proc.new)
      )
    end

    it "returns an Event" do
      expect(subject.send(:service_event_item_to_event_model, item)).to be_a Event
    end

    it "creates a new instance but does not save it" do
      existing_event.destroy

      expect(
        subject
          .send(:service_event_item_to_event_model, item)
          .new_record?
      ).to be true
    end

    context "when event exists in db" do

      it "finds an existing event by external_id" do
        expect(
          subject.send(:service_event_item_to_event_model, item)
        ).to eq existing_event
      end

      context "with start.date.date" do
        it "updates start_at" do
          event = subject_with_item{ |i|
            i.start.date = Date.today.strftime('%Y-%m-%d')
            i.start.date_time = nil
            i.start.time_zone = 'America/Los_Angeles'
          }

          expect(
            event
              .start_at
              .to_s
          ).to eq ActiveSupport::TimeZone.new('America/Los_Angeles').local_to_utc(Time.now.beginning_of_day).to_s
        end

        it "updates end_at" do
          event = subject_with_item{ |i|
            i.end.date = Date.today.strftime('%Y-%m-%d')
            i.end.date_time = nil
            i.end.time_zone = 'America/Los_Angeles'
          }

          expect(
            event
              .end_at
              .to_s
          ).to eq ActiveSupport::TimeZone.new('America/Los_Angeles').local_to_utc(Time.now.beginning_of_day).to_s
        end
      end

      context "with start.date.date_time" do
        it "updates start_at" do
          event = subject_with_item{ |i|
            i.start.date = nil
            i.start.date_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
            i.start.time_zone = nil
          }

          expect(
            event
              .start_at
          ).to be_within(1.second).of(Time.now)
        end

        it "updates end_at" do
          event = subject_with_item{ |i|
            i.end.date = nil
            i.end.date_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
            i.end.time_zone = nil
          }

          expect(
            event
              .end_at
          ).to be_within(1.second).of(Time.now)
        end
      end

      it "updates name" do
        event = subject_with_item{ |i|
          item.summary = "new name"
        }

        expect(
          event
            .name
        ).to eq "new name"
      end

      it "looks for source_event_id in the description" do
        event = subject_with_item{ |i|
          item.description = Faker::Lorem.sentence + "\n\nSourceEvent#123"
        }

        expect(
          event
            .source_event_id
        ).to eq 123
      end
    end
  end
end
