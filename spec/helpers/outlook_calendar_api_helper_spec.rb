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

  # API config
  let(:event_fields) { %w{Id Subject BodyPreview Start End IsAllDay IsCancelled ShowAs} }

  # Account data
  let(:access_token) { Faker::Internet.unique.password(10, 20) }
  let(:account) { create :remote_account, access_token: access_token }
  let(:email) { generate(:email) }

  # Calendar data
  let(:calendar_id) { Faker::Internet.unique.password(10, 20) }
  let(:calendar) { create :calendar, remote_account: account }

  # Event data
  let(:start_at) { 5.minutes.ago.to_datetime }
  let(:end_at) { 5.minutes.from_now.to_datetime }
  let(:is_attending) { false }
  let(:event_external_id) { Faker::Internet.unique.password(10, 20) }
  let(:event_description) { '' }

  let(:event) {
    build(:event,
      calendar: calendar,
      start_at: start_at,
      end_at: end_at,
      is_attending: is_attending
    )
  }

  let(:existing_event) {
    create(:event,
      external_id: event_external_id,
      calendar: calendar
    )
  }

  let(:events) { [event] }

  let(:start_at_str) { start_at.strftime('%Y-%m-%dT%H:%M:%S') }
  let(:end_at_str) { end_at.strftime('%Y-%m-%dT%H:%M:%S') }
  let(:is_cancelled) { false }
  let(:response) { 'None' }

  let(:outlook_event_show_as) {
    # Free = 0, Tentative = 1, Busy = 2, Oof = 3, WorkingElsewhere = 4, Unknown = -1.
    if event.is_attending then 2 else 0 end
  }

  let(:outlook_formatted_event) {
    {
      'Body' => {
        'ContentType' => 0,
        'Content' => event_description,
      },
      'Start' => {
        'DateTime' => start_at_str,
        'TimeZone' => 'Etc/GMT',
      },
      'End' => {
        'DateTime' => end_at_str,
        'TimeZone' => 'Etc/GMT',
      },
      'Subject' => event.name,
      'Sensitivity' => 0,
      'ShowAs' => outlook_event_show_as,
      'Type' => 0,
      'IsCancelled' => is_cancelled,
      # # TODO:
      # IsAllDay:
      #
    }
  }
  let(:outlook_event_with_america_timezone) {
    outlook_formatted_event.dup.tap{ |ofe|
      ofe['Start']['TimeZone'] = 'America/Los_Angeles'
      ofe['End']['TimeZone'] = 'America/Los_Angeles'
    }
  }
  let(:outlook_event_with_id) {
    outlook_formatted_event.dup.tap{ |ofe| ofe['Id'] = event_external_id }
  }
  let(:outlook_event_with_id_and_response) {
    outlook_event_with_id.dup.tap{ |ofe| ofe['ResponseStatus'] = { 'Response' => response } }
  }
  let(:outlook_event_shown_as_free) {
    outlook_formatted_event.dup.tap{ |ofe| ofe['ShowAs'] = 1 }
  }
  let(:outlook_event_with_id_and_america_timezone) {
    outlook_event_with_america_timezone.dup.tap{ |ofe|
      ofe['Id'] = event_external_id
    }
  }

  let(:raw_outlook_calendar_view_response) {
    {
      "@odata.context" => "https://outlook.office.com/api/v2.0/me/calendars/{calendar_id}/events",
      "value" => [
        outlook_event_with_id_and_america_timezone,
        outlook_event_shown_as_free,
      ]
    }
  }

  describe "#delete_event" do
    subject { OutlookCalendarApiHelper.delete_event(access_token, event_external_id) }

    before(:each) {
      expect(client)
        .to receive(:delete_event)
        .with(access_token, event_external_id)
    }

    it { is_expected.to be_nil }
  end

  describe "#get_event" do
    subject { OutlookCalendarApiHelper.get_event(access_token, email, event_external_id) }

    before(:each) {
      expect(client)
        .to receive(:get_event_by_id)
        .with(access_token, event_external_id, event_fields)
        .and_return(outlook_event_with_id)

      expect(OutlookCalendarApiHelper)
        .to receive(:upsert_service_event_item)
        .with(email, outlook_event_with_id)
        .and_return(existing_event)
    }

    it { is_expected.to eq existing_event }
  end

  describe "#move_event" do
    let(:new_start_at) { Faker::Time.forward(23, :morning).utc }
    let(:new_end_at) { new_start_at + Faker::Number.between(1, 10).hours }

    subject { OutlookCalendarApiHelper.move_event(access_token, event_external_id, new_start_at, new_end_at) }

    before(:each) {
      expect(client)
        .to receive(:update_event)
        .with(
          access_token,
          hash_including(
            'Start' => {
              'DateTime' => new_start_at.strftime('%Y-%m-%dT%H:%M:%S'),
              'TimeZone' => 'Etc/GMT',
            },
            'End' => {
              'DateTime' => new_end_at.strftime('%Y-%m-%dT%H:%M:%S'),
              'TimeZone' => 'Etc/GMT',
            },
          ),
          event_external_id
        )
    }

    it { is_expected.to be_nil }
  end


  describe "#request_calendars" do
    subject { OutlookCalendarApiHelper.request_calendars(access_token) }

    let(:outlook_formatted_calendar) {
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

    let(:raw_outlook_calendar_response) {
      {
        "@odata.context" => "https://outlook.office.com/api/v2.0/$metadata#Me/Calendars",
        "value" => [
          outlook_formatted_calendar,
          outlook_formatted_calendar,
        ],
      }
    }

    before(:each) {
      expect(client).to receive(:get_calendars)
        .with(access_token, any_args)
        .and_return(raw_outlook_calendar_response)
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

  describe "#upsert_service_calendar_item" do
    subject { OutlookCalendarApiHelper.send(:upsert_service_calendar_item, item) }

    let(:name) { Faker::Lorem.sentence }

    let(:item) {
      {
        CanEdit: can_edit,
        Id: calendar_id,
        Name: name,
      }.to_ostruct
    }

    context "writeable calendar" do
      let(:can_edit) { true }

      it {
        is_expected.to have_attributes(
          time_zone: nil,
          name: name,
          external_id: calendar_id,
        )
      }
    end

    # context "read-only calendar" do
    #   let(:can_edit) { false }

    #   it { is_expected.to be_nil }
    # end
  end

  describe "#request_events" do
    subject { OutlookCalendarApiHelper.request_events(access_token, email, calendar_id) }

    before(:each) {
      expect(client)
        .to receive(:get_calendar_view)
        .with(access_token, instance_of(DateTime), instance_of(DateTime), calendar_id, event_fields)
        .and_return(raw_outlook_calendar_view_response)

      expect(OutlookCalendarApiHelper)
        .to receive(:upsert_service_event_item)
        .with(email, outlook_event_with_id_and_america_timezone)
        .and_return(event)

      expect(OutlookCalendarApiHelper)
        .to receive(:upsert_service_event_item)
        .with(email, outlook_event_shown_as_free)
        .and_return(nil)
    }

    it { is_expected.to include(event) }
    it { is_expected.not_to include(nil) }
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
      let(:is_attending) { true }

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
              persisted?: true,
              external_id: event_external_id
            )
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
              hash_including('Subject' => a.name),
              hash_including('Subject' => b.name),
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
              hash_including('Subject' => c.name),
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

    before(:each) {
      expect(client)
        .to receive(:batch_create_events)
        .with(
          access_token,
          [
            hash_including(outlook_formatted_event),
          ],
          calendar_id
        )
        .and_return([outlook_event_with_id])
    }

    after(:each) {
      expect(event.external_id)
        .to eq outlook_event_with_id['Id']
    }

    it { is_expected.to include event }
  end

  describe "#upsert_service_event_item" do
    subject {
      OutlookCalendarApiHelper
        .send(
          :upsert_service_event_item,
          existing_event.remote_account.email,
          outlook_event_with_id_and_response
        )
    }

    let(:outlook_event_show_as) { 2 }

    it { is_expected.to be_a Event }

    context "when ShowAs < 2" do
      context "when ShowAs == 1" do
        let(:outlook_event_show_as) { 1 }
        it { is_expected.to be_nil }
      end

      context "when ShowAs == 0" do
        let(:outlook_event_show_as) { 0 }
        it { is_expected.to be_nil }
      end

      context "when ShowAs == -1" do
        let(:outlook_event_show_as) { -1 }
        it { is_expected.to be_nil }
      end

    end

    context "with a previously un-seen event" do
      before(:each) do
        existing_event.destroy
      end

      it {
        is_expected.to have_attributes(
          new_record?: true,
          persisted?: false
        )
      }

      context "that's been cancelled" do
        before(:each) { outlook_formatted_event['IsCancelled'] = true }

        it "won't mirror the event" do
          expect{ subject }.not_to change{ Event.count }
        end

        it { is_expected.to be_nil }
      end
    end

    context "when event exists in db" do
      it "finds an existing event by external_id" do
        expect(
          subject
        ).to eq existing_event
      end

      describe "start_at and end_at" do
        before(:each) {
          expect(event.start_at)
            .not_to eq existing_event.start_at

          expect(event.end_at)
            .not_to eq existing_event.end_at
        }

        it {
          is_expected.to have_attributes(
            start_at: within(1.second).of(start_at),
            end_at: within(1.second).of(end_at)
          )
        }
      end

      describe "is_attending" do
        context "when Response is None" do
          let(:response) { 'None' }

          it { is_expected.to have_attributes is_attending: false }
        end

        context "when Response is Organizer" do
          let(:response) { 'Organizer' }

          it { is_expected.to have_attributes is_attending: true }
        end

        context "when Response is TentativelyAccepted" do
          let(:response) { 'TentativelyAccepted' }

          it { is_expected.to have_attributes is_attending: true }
        end

        context "when Response is Accepted" do
          let(:response) { 'Accepted' }

          it { is_expected.to have_attributes is_attending: true }
        end

        context "when Response is Declined" do
          let(:response) { 'Declined' }

          it { is_expected.to have_attributes is_attending: false }
        end

        context "when Response is NotResponded" do
          let(:response) { 'NotResponded' }

          it { is_expected.to have_attributes is_attending: false }
        end
      end

      context "when description contains a source event id" do
        let(:event_description) { Faker::Lorem.sentence + "\n\nSourceEvent#123" }
        it { is_expected.to have_attributes(source_event_id: 123) }
      end
    end
  end
end
