# frozen_string_literal: true

require "rails_helper"
require "ostruct"

describe CalendarApiHelper::Google do
  let(:service) { double('service') }
  let(:batch) { double('batch') }
  let(:transparency) { 'transparent' }
  let(:google_formatted_event) {
    {
      start: {
        date_time: Time.now
      },
      attendees: [],
      end: {
        date_time: Time.now + 1.day
      },
      summary: Faker::Lorem.sentence,
      description: "",
      transparency: transparency,
    }.to_ostruct
  }
  let(:google_formatted_event_with_date_times) {
    google_formatted_event
      .to_h
      .merge(
        start: {
          date_time: Time.now
        },
        end: {
          date_time: Time.now + 1.day
        },
      )
      .to_ostruct
  }
  let(:google_formatted_event_with_dates) {
    google_formatted_event
      .to_h
      .merge(
        start: {
          date: Date.today
        },
        end: {
          date: Date.today + 1.day
        },
      )
      .to_ostruct
  }
  let(:item) { google_formatted_event }

  let(:access_token) { Faker::Internet.unique.password(10, 20) }
  let(:calendar_id) { Faker::Internet.unique.password(10, 20) }

  before(:each) {
    allow(CalendarApiHelper::Google)
      .to receive(:build_service)
      .and_return(service)

    allow(item)
      .to receive(:id)
      .and_return(Faker::Internet.unique.password(10, 20))
  }

  describe "embedding and extracting source_event_id" do
    it "embeds and extracts the source_event_id" do
      shadow = create :event, :is_shadow

      expect(service)
        .to receive(:batch)
        .and_yield(batch)

      expect(batch)
        .to receive(:insert_event)
        .with(
          calendar_id,
          have_attributes(
            description: end_with("SourceEvent##{shadow.source_event_id}"),
          )
        )

      CalendarApiHelper::Google.push_events(access_token, calendar_id, [shadow])

      allow(item)
        .to receive(:description)
        .and_return("lorem ipsum \n\n\n\n\nSourceEvent##{shadow.source_event_id}")

      expect(CalendarApiHelper::Google.send(:upsert_service_event_item, '', item))
        .to have_attributes(source_event_id: shadow.source_event_id)
    end
  end

  describe "#request_events" do
    let(:email) { generate(:email) }

    subject { CalendarApiHelper::Google.request_events(access_token, email, calendar_id) }

    before(:each) {
      allow(CalendarApiHelper::Google)
        .to receive(:build_service)
        .and_return(service)

      allow(CalendarApiHelper::Google)
        .to receive(:get_calendar_events)
        .and_return([item])

      allow(CalendarApiHelper::Google)
        .to receive(:upsert_service_event_item)
        .with(email, item)
        .and_return([nil])
    }

    it { is_expected.not_to include(nil) }
  end

  describe "#upsert_service_calendar_item" do
    subject { CalendarApiHelper::Google.send(:upsert_service_calendar_item, item) }

    let(:item) {
      {
        summary: Faker::Lorem.sentence,
        time_zone: 'Europe/Zurich',
      }.to_ostruct
    }

    before(:each) {
      allow(item)
        .to receive(:id)
        .and_return(Faker::Internet.unique.password(10, 20))
    }

    it "sets the time zone" do
      expect(subject.time_zone)
        .to eq item.time_zone
    end
  end

  describe "#push_events" do
    let(:calendar) { build :calendar }
    subject { CalendarApiHelper::Google.push_events(access_token, calendar_id, events) }

    context "with an empty array of events" do
      let(:events) { [] }
      it { is_expected.to be_nil }
    end

    describe "event.start/end" do
      before(:each) {
        allow(CalendarApiHelper::Google)
          .to receive(:build_service)
          .and_return(service)

        expect(service)
          .to receive(:batch)
          .and_yield(batch)
      }

      context "when event is all day" do
        let(:events) { [create(:event, :all_day, :is_shadow, calendar: calendar)] }

        before(:each) {
          expect(batch)
            .to receive(:insert_event)
            .with(
              calendar_id,
              have_attributes(
                start: hash_including(
                  date: match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/),
                  time_zone: calendar.time_zone,
                ),
                end: hash_including(
                  date: match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/),
                  time_zone: calendar.time_zone,
                ),
              )
            )
        }

        it { is_expected.to include(have_attributes(is_all_day: true)) }
      end

      context "when event is not all day" do
        let(:events) { [create(:event, :is_shadow, calendar: calendar)] }

        before(:each) {
          expect(batch)
            .to receive(:insert_event)
            .with(
              calendar_id,
              have_attributes(
                start: hash_including(
                  date_time: match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}T/),
                ),
                end: hash_including(
                  date_time: match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}T/),
                ),
              )
            )
        }

        it { is_expected.to include(have_attributes(is_all_day: false)) }
      end
    end
  end

  describe "#move_event" do
    let(:in_time_zone) { Time.zone.name }
    let(:new_start_at) { (Time.now + 2.days).in_time_zone(in_time_zone) }
    let(:new_end_at) { new_start_at + 2.hours }
    let(:event_id) { Faker::Internet.password(10, 20) }

    before(:each) {
      allow(CalendarApiHelper::Google)
        .to receive(:build_service)
        .and_return(service)
    }

    subject { CalendarApiHelper::Google.move_event(access_token, calendar_id, event_id, new_start_at, new_end_at, new_is_all_day, in_time_zone) }

    context "when is_all_day" do
      let(:new_is_all_day) { true }

      it "patches the new dates with Date and time_zone" do
        expect(service)
          .to receive(:patch_event)
          .with(
            calendar_id,
            event_id,
            have_attributes(
              start: {
                date: new_start_at.strftime('%Y-%m-%d'),
                time_zone: in_time_zone,
              },
              end: {
                date: new_end_at.strftime('%Y-%m-%d'),
                time_zone: in_time_zone,
              }
            )
          )

        subject
      end
    end

    context "when NOT is_all_day" do
      let(:new_is_all_day) { false }

      it "patches the new dates with Date and time_zone" do
        expect(service)
          .to receive(:patch_event)
          .with(
            calendar_id,
            event_id,
            have_attributes(
              start: {
                date_time: new_start_at.iso8601,
              },
              end: {
                date_time: new_end_at.iso8601,
              }
            )
          )

        subject
      end
    end
  end

  describe "#upsert_service_event_item" do
    subject {
      CalendarApiHelper::Google
        .send(
          :upsert_service_event_item,
          existing_event.remote_account.email,
          item
        )
    }

    let!(:existing_event) { create :event, external_id: Faker::Internet.password(10, 20) }

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

    describe "is_blocking" do
      context "when transparent" do
        let(:transparency) { 'transparent' }

        it { is_expected.to have_attributes(is_blocking: false) }
      end

      context "when opaque" do
        let(:transparency) { 'opaque' }

        it { is_expected.to have_attributes(is_blocking: true) }
      end
    end

    describe "is_all_day" do
      context "when item is not day" do
        let(:item) { google_formatted_event_with_date_times }

        it { is_expected.to have_attributes is_all_day: false }
      end

      context "when item is all day" do
        let(:item) { google_formatted_event_with_dates }

        it { is_expected.to have_attributes is_all_day: true }
      end
    end

    context "with cancelled event" do
      let(:item) {
        {
          etag: "3040935482068000",
          id: "arc0vggjo2h1hqk7btopa8thd4",
          kind: "calendar#event",
          status: "cancelled"
        }.to_ostruct
      }

      it "won't mirror the event" do
        expect{ subject }.not_to(change{ Event.count })
      end
    end

    context "when event exists in db" do
      it "finds an existing event by external_id" do
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
                email: existing_event.remote_account.email,
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
                email: existing_event.remote_account.email,
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
                email: existing_event.remote_account.email,
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
                email: existing_event.remote_account.email,
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
