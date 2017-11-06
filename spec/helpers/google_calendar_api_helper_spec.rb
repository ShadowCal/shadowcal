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
        attendees: [],
        end: {
          date: Date.today + 1.day
        },
        summary: Faker::Lorem.sentence,
        description: "",
      }.to_ostruct
    }

    def result
      subject.send(
        :service_event_item_to_event_model,
        existing_event.google_account.email,
        item
      )
    end

    it "returns an Event" do
      expect(result).to be_a Event
    end

    context "with an un-previously-seen event" do
      before(:each) do
        existing_event.destroy
      end

      it "creates a new instance but does not save it" do
        expect(
          result
            .new_record?
        ).to be true
      end
    end

    context "when event exists in db" do
      it "finds an existing event by external_id" do
        expect(
          result
        ).to eq existing_event
      end

      context "with start.date.date" do
        it "updates start_at" do
          item.start.date = Date.today.strftime('%Y-%m-%d')
          item.start.date_time = nil
          item.start.time_zone = 'America/Los_Angeles'

          expect(
            result
              .start_at
              .to_s
          ).to eq ActiveSupport::TimeZone.new('America/Los_Angeles').local_to_utc(Time.now.beginning_of_day).to_s
        end

        it "updates end_at" do
          item.end.date = Date.today.strftime('%Y-%m-%d')
          item.end.date_time = nil
          item.end.time_zone = 'America/Los_Angeles'

          expect(
            result
              .end_at
              .to_s
          ).to eq ActiveSupport::TimeZone.new('America/Los_Angeles').local_to_utc(Time.now.beginning_of_day).to_s
        end
      end

      context "with start.date.date_time" do
        it "updates start_at" do
          item.start.date = nil
          item.start.date_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
          item.start.time_zone = nil

          expect(
            result
              .start_at
          ).to be_within(1.second).of(Time.now)
        end

        it "updates end_at" do
          item.end.date = nil
          item.end.date_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
          item.end.time_zone = nil

          expect(
            result
              .end_at
          ).to be_within(1.second).of(Time.now)
        end
      end

      it "updates name" do
        item.summary = "new name"

        expect(
          result
            .name
        ).to eq "new name"
      end

      describe "is_attending" do
        context "is set true" do
          before(:each) do
            # Set cached event to not attending, so item can update it to true
            existing_event.update_attributes is_attending: false
          end

          it "when attending" do
            expect(existing_event.is_attending).to be_falsy # sanity

            item.attendees = [
              {
                email: existing_event.google_account.email,
                response_status: 'accepted',
              }.to_ostruct,
              {
                email: 'someone@else.com',
                response_status: 'tentative',
              }.to_ostruct
            ]

            expect(
              result
                .is_attending
            ).to be true
          end
        end

        context "is set false" do
          before(:each) do
            existing_event.update_attributes is_attending: true
          end

          it "when not responded" do
            expect(existing_event.is_attending).to be_truthy # sanity

            item.attendees = [
              {
                email: existing_event.google_account.email,
                response_status: 'needsAction',
              }.to_ostruct,
              {
                email: 'someone@else.com',
                response_status: 'accepted',
              }.to_ostruct
            ]

            expect(
              result
                .is_attending
            ).to be false
          end

          it "when declined" do
            expect(existing_event.is_attending).to be_truthy # sanity

            item.attendees = [
              {
                email: existing_event.google_account.email,
                response_status: 'declined',
              }.to_ostruct,
              {
                email: 'someone@else.com',
                response_status: 'accepted',
              }.to_ostruct
            ]

            expect(
              result
                .is_attending
            ).to be false
          end

          it "when tentative" do
            expect(existing_event.is_attending).to be_truthy # sanity

            item.attendees = [
              {
                email: existing_event.google_account.email,
                response_status: 'tentative',
              }.to_ostruct,
              {
                email: 'someone@else.com',
                response_status: 'accepted',
              }.to_ostruct
            ]

            expect(
              result
                .is_attending
            ).to be false
          end
        end
      end

      it "looks for source_event_id in the description" do
        item.description = Faker::Lorem.sentence + "\n\nSourceEvent#123"

        expect(
          result
            .source_event_id
        ).to eq 123
      end
    end
  end
end
