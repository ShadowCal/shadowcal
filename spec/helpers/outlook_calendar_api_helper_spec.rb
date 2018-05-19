# frozen_string_literal: true

require "rails_helper"
require "ostruct"

describe OutlookCalendarApiHelper do
  let(:client) { double('client') }

  before(:each) {
    allow(OutlookCalendarApiHelper)
      .to receive(:client)
      .and_return(client)
  }

  let(:access_token) { Faker::Internet.unique.password(10, 20) }
  let(:calendar_id) { Faker::Internet.unique.password(10, 20) }

  describe "#request_calendars" do
    subject { OutlookCalendarApiHelper.request_calendars(access_token) }

    let(:calendar_response) {
      {
        "@odata.id" => "https://outlook.office.com/api/v2.0/Users('ddfcd489-628b-40d7-b48b-57002df800e5@1717622f-1d94-4d0c-9d74-709fad664b77')/Calendars('AAMkAGI2TGuLAAA=')",
        "Id" => calendar_id,
        "Name" => "Calendar Name",
        "Color" => "Auto",
        "ChangeKey" => "nfZyf7VcrEKLNoU37KWlkQAAA0x0+w==",
        "CanShare" => true,
        "CanViewPrivateItems" => true,
        "CanEdit" => true,
        "Owner" => {
          "Name" => "Fanny Downs",
          "Address" => "fannyd@adatum.onmicrosoft.com"
        }
      }.to_h
    }

    let(:raw_calendar_response) {
      {
        "@odata.context" => "https://outlook.office.com/api/v2.0/$metadata#Me/Calendars",
        "value" => [ calendar_response, calendar_response ],
      }
    }

    before(:each) {
      expect(client).to receive(:get_calendars)
        .with(access_token, any_args)
        .and_return(raw_calendar_response)
    }

    it 'uniquely upserts' do
      expect{ subject }
        .to change{ Calendar.count }.by(1)
    end

    it {
      is_expected.to include(
        have_attributes(
          external_id: calendar_id,
          name: 'Calendar Name',
        )
      )
    }
  end

  describe "#request_events" do
    let(:email) { generate(:email) }

    subject { OutlookCalendarApiHelper.request_events(access_token, email, calendar_id) }

    let(:fields) { %w{Id Subject BodyPreview Start End IsAllDay IsCancelled ShowAs} }

    let(:id) { Faker::Internet.unique.password(10, 20) }
    let(:start_at_str) { 5.minutes.ago.strftime('%Y-%m-%dT%H:%M:%S') }
    let(:end_at_str) { 5.minutes.from_now.strftime('%Y-%m-%dT%H:%M:%S') }

    let(:event) {
      {
        'Id' => id,
        'Subject' => 'name of event',
        # Body: text | html
        'BodyPreview' => 'short description',
        # Calendar:
        'Start' => {
          'DateTime' => start_at_str,
          'TimeZone' => 'America/Los_Angeles',
        },
        'End' => {
          'DateTime' => end_at_str,
          'TimeZone' => 'America/Los_Angeles',
        },
        # iCalUID:
        'IsAllDay' => false,
        'IsCancelled' => false,
        # IsOrganizer:
        # Recurrence: PatternedRecurrence, #https://msdn.microsoft.com/en-us/office/office365/api/complex-types-for-mail-contacts-calendar#PatternedRecurrence
        # Instances:
        # ResponseStatus
        # Sensitivity: Normal = 0, Personal = 1, Private = 2, Confidential = 3.
        'ShowAs' => 0, # Free = 0, Tentative = 1, Busy = 2, Oof = 3, WorkingElsewhere = 4, Unknown = -1.
      }
    }

    before(:each) {
      expect(client)
        .to receive(:get_calendar_view)
        .with(access_token, instance_of(DateTime), instance_of(DateTime), calendar_id, fields)
        .and_return(
          "@odata.context" => "https://outlook.office.com/api/v2.0/me/calendars/{calendar_id}/events",
          "value" => [event, event]
        )
    }

    it {
      is_expected.to include(
        have_attributes(
          name: 'name of event',
          start_at: ZoneHelper.from_date_str_and_zone_to_utc(start_at_str, 'America/Los_Angeles'),
          end_at: ZoneHelper.from_date_str_and_zone_to_utc(end_at_str, 'America/Los_Angeles'),
          external_id: id,
          source_event_id: nil,
          is_attending: false,
          persisted?: false,
        )
      )
    }
  end

  describe "#upsert_service_calendar_item" do
    subject { OutlookCalendarApiHelper.send(:upsert_service_calendar_item, item) }

    let(:name) { Faker::Lorem.sentence }
    let(:external_id) { Faker::Internet.unique.password(10, 20) }
    let(:CanEdit) { true }

    let(:item) {
      {
        # # TODO: support read-only calendars
        # CanEdit: CanEdit,
        Id: external_id,
        Name: name,
      }.to_ostruct
    }

    it {
      is_expected.to have_attributes(
        time_zone: nil,
        name: name,
        external_id: external_id,
      )
    }
  end

  describe "#push_events" do
    let(:batch_size) { 20 }
    subject { OutlookCalendarApiHelper.push_events(access_token, calendar_id, events, batch_size) }

    context "with an empty array of events" do
      let(:events) { [] }
      it { is_expected.to eq [] }
    end

    # TODO: Edge cases? eg all day event or wild time zones
    context "with an event" do
      let(:start_at) { 5.minutes.ago.to_datetime }
      let(:end_at) { 5.minutes.from_now.to_datetime }
      let(:event) { build :event, start_at: start_at, end_at: end_at }
      let(:events) { [event] }
      let(:event_external_id) { Faker::Internet.unique.password(10, 20) }
      let(:outlook_formatted_event) {
        {
          Body: event.description,
          Start: {
            'DateTime' => start_at.strftime('%Y-%m-%dT%H:%M:%S'),
            'TimeZone' => 'Etc/GMT',
          },
          End: {
            'DateTime' => end_at.strftime('%Y-%m-%dT%H:%M:%S'),
            'TimeZone' => 'Etc/GMT',
          },
          Subject: event.name,
          Sensitivity: 0,
          ShowAs: 2,
          Type: 0,
          # # TODO:
          # IsAllDay:
          #
        }
      }
      let(:outlook_event_with_id) {
        outlook_formatted_event.dup.tap{ |ofe| ofe['Id'] = event_external_id }
      }

      before(:each) {
        expect(client)
          .to receive(:batch_create_events)
          .with(
            access_token,
            array_including(
              hash_including(outlook_formatted_event)
            ),
            calendar_id
          )
        .and_return([outlook_event_with_id])
      }

      it {
        is_expected
          .to contain_exactly(
            have_attributes(
              external_id: event_external_id
            )
          )
      }

      after(:each) {
        expect(event)
          .to have_attributes(
            persisted?: true,
            external_id: event_external_id
          )
      }
    end

    context "with multiple events" do
      let(:a) { build :event }
      let(:b) { build :event }
      let(:c) { build :event }
      let(:events) { [a, b, c] }

      let(:id_a) { Faker::Internet.unique.password(10, 20) }
      let(:id_b) { Faker::Internet.unique.password(10, 20) }
      let(:id_c) { Faker::Internet.unique.password(10, 20) }

      let(:batch_size) { 2 }

      before(:each) {
        expect(client)
          .to receive(:batch_create_events)
          .with(
            access_token,
            [
              hash_including(Subject: a.name),
              hash_including(Subject: b.name),
            ],
            calendar_id
          )
          .and_return([
            { 'Id' => id_a },
            { 'Id' => id_b },
          ])
          .ordered

        expect(client)
          .to receive(:batch_create_events)
          .with(
            access_token,
            [
              hash_including(Subject: c.name),
            ],
            calendar_id
          )
          .and_return([
            { 'Id' => id_c },
          ])
          .ordered
      }

      it {
        is_expected
          .to contain_exactly(
            have_attributes(
              external_id: id_a,
            ),
            have_attributes(
              external_id: id_b,
            ),
            have_attributes(
              external_id: id_c,
            ),
          )
      }

    end
  end

  describe "#push_event" do
    subject { OutlookCalendarApiHelper.push_event(access_token, calendar_id, event) }

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
      OutlookCalendarApiHelper
        .send(
          :upsert_service_event_item,
          existing_event.remote_account.email,
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
