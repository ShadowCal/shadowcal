# frozen_string_literal: true

require "rails_helper"
require "ostruct"

describe GoogleCalendarApiHelper do
  let(:service) { double('service') }
  let(:item) { double('item') }

  before(:each) {
    allow(GoogleCalendarApiHelper)
      .to receive(:build_service)
      .and_return(service)

    allow(item)
      .to receive(:id)
      .and_return(Faker::Internet.unique.password(10, 20))
  }

  describe "#push_event" do
    subject { GoogleCalendarApiHelper.push_event(access_token, calendar_id, event) }

    let(:access_token) { Faker::Internet.unique.password(10, 20) }
    let(:calendar_id) { Faker::Internet.unique.password(10, 20) }
    let(:event) { create :event, external_id: nil }

    before(:each) {
      expect(service)
        .to receive(:insert_event)
        .with(calendar_id, instance_of(Google::Apis::CalendarV3::Event))
        .and_return(item)
    }

    after(:each) {
      expect(event.external_id)
        .to eq item.id
    }

    it { is_expected.to be true }
  end

  describe "#upsert_service_event_item" do
    subject {
      GoogleCalendarApiHelper
        .send(
          :upsert_service_event_item,
          existing_event.google_account.email,
          item
        )
    }

    let!(:existing_event) { create :event, external_id: Faker::Internet.password(10, 20) }
    let(:item) {
      {
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

    before(:each) {
      allow(item).to receive(:id).and_return(existing_event.external_id)
    }

    it "returns an Event" do
      expect(subject).to be_a Event
    end

    context "with an un-previously-seen event" do
      before(:each) do
        existing_event.destroy
      end

      it "creates a new instance but does not save it" do
        expect(
          subject
            .new_record?
        ).to be true
      end
    end

    context "when event exists in db" do
      it "finds an existing event by external_id" do

        # puts "ITEM ID WAS ORIGINALLY", item.id
        # existing_event.update_attributes external_id: 'abc123'
        # item[:id] = existing_event.external_id

        # puts "LOOKING FOR EVENT", existing_event.inspect
        # puts "BASED ON ITEM", item.inspect
        # puts "WITH ITEM.ID", item.id.inspect

        expect(
          subject
        ).to eq existing_event
      end

      context "with start.date.date" do
        it "updates start_at" do
          item.start.date = Date.today.strftime('%Y-%m-%d')
          item.start.date_time = nil
          item.start.time_zone = 'America/Los_Angeles'

          expect(
            subject
              .start_at
              .to_s
          ).to eq ActiveSupport::TimeZone.new('America/Los_Angeles').local_to_utc(Time.now.beginning_of_day).to_s
        end

        it "updates end_at" do
          item.end.date = Date.today.strftime('%Y-%m-%d')
          item.end.date_time = nil
          item.end.time_zone = 'America/Los_Angeles'

          expect(
            subject
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
            subject
              .start_at
          ).to be_within(1.second).of(Time.now)
        end

        it "updates end_at" do
          item.end.date = nil
          item.end.date_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
          item.end.time_zone = nil

          expect(
            subject
              .end_at
          ).to be_within(1.second).of(Time.now)
        end
      end

      it "updates name" do
        item.summary = "new name"

        expect(
          subject
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
              subject
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
              subject
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
              subject
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
              subject
                .is_attending
            ).to be false
          end
        end
      end

      it "looks for source_event_id in the description" do
        item.description = Faker::Lorem.sentence + "\n\nSourceEvent#123"

        expect(
          subject
            .source_event_id
        ).to eq 123
      end
    end
  end
end
