# frozen_string_literal: true

require "rails_helper"
require "ostruct"

describe CalendarApiHelper::Outlook do
  let(:client) { double('client') }

  before(:each) {
    allow(CalendarApiHelper::Outlook)
      .to receive(:client)
      .and_return(client)
  }

  # API config
  let(:event_fields) { %w{Id Subject Body Start End IsAllDay IsCancelled ShowAs ResponseStatus} }

  # Account data
  let(:access_token) { Faker::Internet.unique.password(10, 20) }
  let(:email) { generate(:email) }
  let(:account) { create :remote_account, access_token: access_token, email: email }

  # Calendar data
  let(:time_zone) { 'Asia/Kolkata' }
  let(:calendar_id) { Faker::Internet.unique.password(10, 20) }
  let(:calendar) { create :calendar, remote_account: account, external_id: calendar_id, time_zone: time_zone }

  # Event data
  let(:start_at) { 5.minutes.ago.to_datetime }
  let(:end_at) { 5.minutes.from_now.to_datetime }
  let(:is_attending) { false }
  let(:event_external_id) { Faker::Internet.unique.password(10, 20) }
  let(:event_description) { '' }

  let(:event) {
    build(
      :event,
      calendar:     calendar,
      start_at:     start_at,
      end_at:       end_at,
      is_attending: is_attending
    )
  }

  let(:existing_event) {
    create(
      :event,
      external_id: event_external_id,
      calendar:    calendar
    )
  }

  let(:events) { [event] }

  let(:start_at_str) { start_at.in_time_zone(outlook_formatted_timezone).strftime('%Y-%m-%dT%H:%M:%S') }
  let(:end_at_str) { end_at.in_time_zone(outlook_formatted_timezone).strftime('%Y-%m-%dT%H:%M:%S') }
  let(:is_cancelled) { false }
  let(:is_all_day) { false }
  let(:response) { 'None' }

  let(:outlook_event_show_as) {
    event.is_attending ? 'busy' : 'free'
  }

  let(:outlook_formatted_timezone) { 'Etc/GMT' }

  let(:outlook_formatted_event) {
    {
      'Body'           => {
        'ContentType' => 'Text',
        'Content'     => event_description,
      },
      'Start'          => {
        'DateTime' => start_at_str,
        'TimeZone' => outlook_formatted_timezone,
      },
      'End'            => {
        'DateTime' => end_at_str,
        'TimeZone' => outlook_formatted_timezone,
      },
      'Subject'        => event.name,
      'Sensitivity'    => 'normal',
      'ShowAs'         => outlook_event_show_as,
      'IsCancelled'    => is_cancelled,
      'ResponseStatus' => {
        'Response' => response,
      },
      'IsAllDay'       => is_all_day,
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
    outlook_formatted_event.dup.tap{ |ofe| ofe['ShowAs'] = 'free' }
  }
  let(:outlook_event_with_description) {
    outlook_formatted_event.dup.tap{ |ofe| ofe[''] }
  }
  let(:outlook_event_with_id_and_america_timezone) {
    outlook_event_with_america_timezone.dup.tap{ |ofe|
      ofe['Id'] = event_external_id
    }
  }

  let(:raw_outlook_calendar_view_response) {
    {
      "@odata.context" => "https://outlook.office.com/api/v2.0/me/calendars/{calendar_id}/events",
      "value"          => [
        outlook_event_with_id_and_america_timezone,
        outlook_event_shown_as_free,
      ]
    }
  }

  describe "embedding and extracting the source event's ID" do
    let(:event) { create :event, :is_shadow }
    let(:event_description) { "lorem ipsum \n\n\n\n\nSourceEvent##{event.source_event_id}" }

    it "embeds and extracts the shadow's source_event_id" do
      expect(client)
        .to receive(:create_event) do |_access_token, item|
          expect(item['Body']['Content'])
            .to end_with("SourceEvent##{event.source_event_id}")

          outlook_formatted_event
        end

      CalendarApiHelper::Outlook.push_events(access_token, calendar_id, events)

      expect(CalendarApiHelper::Outlook.send(:upsert_service_event_item, '', outlook_formatted_event, nil))
        .to have_attributes(source_event_id: event.source_event_id)
    end
  end

  describe "#delete_event" do
    subject { CalendarApiHelper::Outlook.delete_event(access_token, event_external_id) }

    before(:each) {
      expect(client)
        .to receive(:delete_event)
        .with(access_token, event_external_id)
    }

    it { is_expected.to be_nil }
  end

  describe "#move_event" do
    let(:new_start_at) { Faker::Time.forward(23, :morning).utc }
    let(:new_end_at) { new_start_at + Faker::Number.between(1, 10).hours }
    let(:new_is_all_day) { false }
    let(:in_time_zone) { "UTC" }

    subject { CalendarApiHelper::Outlook.move_event(access_token, calendar_id, event_external_id, new_start_at, new_end_at, new_is_all_day, in_time_zone) }

    before(:each) {
      expect(client)
        .to receive(:update_event)
        .with(
          access_token,
          hash_including(
            'Start' => {
              'DateTime' => new_start_at.strftime('%Y-%m-%dT%H:%M:%S'),
              'TimeZone' => outlook_formatted_timezone,
            },
            'End'   => {
              'DateTime' => new_end_at.strftime('%Y-%m-%dT%H:%M:%S'),
              'TimeZone' => outlook_formatted_timezone,
            },
          ),
          event_external_id
        )
    }

    it { is_expected.to be_nil }
  end

  describe "#request_calendars" do
    subject { CalendarApiHelper::Outlook.request_calendars(access_token) }

    let(:outlook_formatted_calendar) {
      {
        "@odata.id"           => "https://outlook.office.com/api/v2.0/Users('ddfcd489-628b-40d7-b48b-57002df800e5@1717622f-1d94-4d0c-9d74-709fad664b77')/Calendars('AAMkAGI2TGuLAAA=')",
        "Id"                  => calendar_id,
        "Name"                => "Calendar Name",
        "Color"               => "Auto",
        "ChangeKey"           => "nfZyf7VcrEKLNoU37KWlkQAAA0x0+w==",
        "CanShare"            => true,
        "CanViewPrivateItems" => true,
        "CanEdit"             => true,
        "Owner"               => {
          "Name"    => "Fanny Downs",
          "Address" => "fannyd@adatum.onmicrosoft.com"
        }
      }.to_h
    }

    let(:raw_outlook_calendar_response) {
      {
        "@odata.context" => "https://outlook.office.com/api/v2.0/$metadata#Me/Calendars",
        "value"          => [
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
          name:        'Calendar Name',
        )
      )
    }
  end

  describe "#upsert_service_calendar_item" do
    subject { CalendarApiHelper::Outlook.send(:upsert_service_calendar_item, item) }

    let(:name) { Faker::Lorem.sentence }

    describe "can edit" do
      let(:item) {
        {
          CanEdit: can_edit,
          Id:      calendar_id,
          Name:    name,
        }.to_ostruct
      }

      context "caledar is writeable" do
        let(:can_edit) { true }

        it {
          is_expected.to have_attributes(
            time_zone:   nil,
            name:        name,
            external_id: calendar_id,
          )
        }
      end
    end

    # context "read-only calendar" do
    #   let(:can_edit) { false }

    #   it { is_expected.to be_nil }
    # end
  end

  describe "#request_events" do
    subject { CalendarApiHelper::Outlook.request_events(access_token, email, calendar_id, TimeZoneHelpers.random_timezone.name) }

    before(:each) {
      expect(client)
        .to receive(:get_calendar_view)
        .with(
          access_token,
          within(10.second).of(Time.zone.now),
          within(10.second).of(1.month.from_now),
          calendar_id,
          event_fields
        )
        .and_return(raw_outlook_calendar_view_response)

      expect(CalendarApiHelper::Outlook)
        .to receive(:upsert_service_event_item)
        .with(email, outlook_event_with_id_and_america_timezone, calendar.time_zone)
        .and_return(event)

      expect(CalendarApiHelper::Outlook)
        .to receive(:upsert_service_event_item)
        .with(email, outlook_event_shown_as_free, calendar.time_zone)
        .and_return(nil)
    }

    it { is_expected.to include(event) }
    it { is_expected.not_to include(nil) }
  end

  describe "#push_events" do
    subject { CalendarApiHelper::Outlook.push_events(access_token, calendar_id, events) }

    context "with an empty array of events" do
      let(:events) { [] }
      it { is_expected.to eq [] }
    end

    # TODO: Edge cases? eg all day event or wild time zones
    context "with an event" do
      let(:event) {
        create(
          :event,
          :is_shadow,
          calendar:     calendar,
          start_at:     start_at,
          end_at:       end_at,
          is_attending: is_attending
        )
      }
      let(:is_attending) { true }
      let(:response) { 'Organizer' }
      let(:event_description) { end_with("SourceEvent##{event.source_event_id}") }

      before(:each) {
        expect(client)
          .to receive(:create_event)
          .with(
            access_token,
            outlook_formatted_event,
            calendar_id
          )
          .and_return(outlook_event_with_id)
      }

      it {
        is_expected
          .to contain_exactly(
            have_attributes(
              persisted?:  true,
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

      before(:each) {
        expect(client)
          .to receive(:create_event)
          .with(
            access_token,
            hash_including('Subject' => a.name),
            calendar_id
          )
          .and_return('Id' => id_a)
          .ordered

        expect(client)
          .to receive(:create_event)
          .with(
            access_token,
            hash_including('Subject' => b.name),
            calendar_id
          )
          .and_return('Id' => id_b)
          .ordered

        expect(client)
          .to receive(:create_event)
          .with(
            access_token,
            hash_including('Subject' => c.name),
            calendar_id
          )
          .and_return('Id' => id_c)
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

  describe "#upsert_service_event_item" do
    subject {
      CalendarApiHelper::Outlook
        .send(
          :upsert_service_event_item,
          existing_event.remote_account.email,
          outlook_event_with_id_and_response,
          existing_event.calendar.time_zone
        )
    }

    let(:outlook_event_show_as) { 'busy' }

    it { is_expected.to be_a Event }

    describe "ShowAs" do
      context "when == tentative" do
        let(:outlook_event_show_as) { 'tentative' }
        it { is_expected.to have_attributes(is_blocking: false) }
      end

      context "when == free" do
        let(:outlook_event_show_as) { 'free' }
        it { is_expected.to have_attributes(is_blocking: false) }
      end

      context "when == unknown" do
        let(:outlook_event_show_as) { 'unknown' }
        it { is_expected.to have_attributes(is_blocking: false) }
      end

      context "when == busy" do
        let(:outlook_event_show_as) { 'busy' }
        it { is_expected.to have_attributes(is_blocking: true) }
      end

      context "when == oof" do
        let(:outlook_event_show_as) { 'oof' }
        it { is_expected.to have_attributes(is_blocking: true) }
      end

      context "when == workingElsewhere" do
        let(:outlook_event_show_as) { 'workingElsewhere' }
        it { is_expected.to have_attributes(is_blocking: true) }
      end
    end

    context "with a previously un-seen event" do
      before(:each) do
        existing_event.destroy
      end

      it {
        is_expected.to have_attributes(
          new_record?: true,
          persisted?:  false
        )
      }

      context "that's been cancelled" do
        before(:each) { outlook_formatted_event['IsCancelled'] = true }

        it "won't mirror the event" do
          expect{ subject }.not_to(change{ Event.count })
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

      across_time_zones do
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
              end_at:   within(1.second).of(end_at)
            )
          }
        end

        describe "is_all_day" do
          # All day events are returned with 00:00:00 times
          let(:start_at) { Time.zone.now.beginning_of_day.utc }
          let(:end_at) { start_at + 1.day }

          context "when item.IsAllDay" do
            let(:is_all_day) { true }

            it {
              is_expected.to have_attributes(
                is_all_day: is_all_day
              )
            }

            it {
              is_expected.to have_attributes(
                start_at: start_at - ActiveSupport::TimeZone.new(existing_event.calendar.time_zone).utc_offset.seconds,
                end_at:   end_at - ActiveSupport::TimeZone.new(existing_event.calendar.time_zone).utc_offset.seconds - 1.second,
              )
            }
          end

          context "when NOT item.IsAllDay" do
            let(:is_all_day) { false }

            it {
              is_expected.to have_attributes(
                is_all_day: is_all_day
              )
            }

            it {
              is_expected.to have_attributes(
                start_at: start_at,
                end_at:   end_at,
              )
            }
          end
        end
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
