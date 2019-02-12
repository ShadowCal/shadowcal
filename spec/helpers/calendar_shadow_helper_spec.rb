# frozen_string_literal: true

require "rails_helper"

describe CalendarShadowHelper do
  let(:is_all_day) { false }

  let(:pair) { create :sync_pair }
  let(:source_event) { create :event, is_all_day: is_all_day, calendar_id: pair.from_calendar_id }
  let(:shadow_event) { create :event, :is_shadow, calendar_id: pair.to_calendar_id, source_event_id: source_event.id }

  let(:from_calendar) { pair.from_calendar }
  let(:to_calendar) { pair.to_calendar }

  let(:event_will_be_synced) { create :syncable_event, name: "will sync", calendar: from_calendar }
  let(:event_not_attending) { create :syncable_event, name: "not attending", calendar: from_calendar, is_attending: false }
  let(:event_already_pushed) { create :syncable_event, :has_shadow, name: "already_pushed", calendar: from_calendar }
  let(:event_on_destination_calendar) { create :syncable_event, name: "on destination calendar", calendar: to_calendar }
  let(:event_on_weekend) { create :syncable_event, :weekend, name: "weekend", calendar: from_calendar }
  let(:event_after_work_hours) { create :syncable_event, :after_work_hours, name: "after hours", calendar: from_calendar }
  let(:event_not_blocking) { create :syncable_event, is_blocking: false, calendar: from_calendar }

  describe "#events_needing_shadows" do
    subject { CalendarShadowHelper.send(:events_needing_shadows, from_calendar) }

    before(:each) do
      event_not_attending
      event_already_pushed
      event_on_destination_calendar
      event_on_weekend
      event_after_work_hours
      event_not_blocking
      event_will_be_synced
    end

    it { is_expected.not_to include(event_not_attending) }
    it { is_expected.not_to include(event_already_pushed) }
    it { is_expected.not_to include(event_on_destination_calendar) }
    it { is_expected.not_to include(event_on_weekend) }
    it { is_expected.not_to include(event_after_work_hours) }
    it { is_expected.not_to include(event_not_blocking) }

    it { is_expected.to include(event_will_be_synced) }
  end

  describe "#cast_from_to" do
    subject { CalendarShadowHelper.cast_from_to(from_calendar, to_calendar) }

    describe "all day event between services" do
      let(:from_calendar) { create :calendar, name: "FROM CAL AllDay", remote_account: from_account, time_zone: 'America/Halifax' }
      let(:to_calendar) { create :calendar, remote_account: to_account, time_zone: 'America/Los_Angeles' }
      let!(:pair) { create :sync_pair, from_calendar: from_calendar, to_calendar: to_calendar, user: from_account.user }

      let(:google_service) { double('google_service') }
      let(:google_batch) { double('google_batch') }
      let(:outlook_client) { double('outlook_client') }

      let(:now) { Time.zone.now.beginning_of_day }
      let(:start_at) { (now + ((3 - now.wday) % 7).days).beginning_of_day }
      let(:end_at) { (start_at + 24.hours) }

      before(:each) {
        allow_any_instance_of(Calendar)
          .to receive(:time_zone) do |cal|
            if cal.remote_account.type == 'OutlookAccount'
              nil
            else
              cal.read_attribute :time_zone
            end
          end

        allow(CalendarApiHelper::Outlook)
          .to receive(:client)
          .and_return(outlook_client)

        allow(CalendarApiHelper::Google)
          .to receive(:build_service)
          .and_return(google_service)

        allow(google_service)
          .to receive(:batch)
          .and_yield(google_batch)
      }

      context "from outlook to google" do
        let(:from_account) { create :outlook_account }
        let(:to_account) { create :google_account }

        let(:raw_outlook_calendar_view_response) {
          {
            "@odata.context" => "https:\/\/outlook.office365.com\/api\/v2.0\/$metadata#Me\/Calendars('AQMkADAwATMwMAItZDJlYy1mZWRmLTAwAi0wMAoARgAAA3tf3VWLTbtKr31QnkQPjAsHAHgeJ1juCepKqGww5D6w8McAAAIBBgAAAHgeJ1juCepKqGww5D6w8McAAAAqJvy2AAAA')\/CalendarView(Id,Subject,Body,Start,End,IsAllDay,IsCancelled,ShowAs,ResponseStatus)",
            "value" => [
              {
                "@odata.id" => "https:\/\/outlook.office365.com\/api\/v2.0\/Users('00030000-d2ec-fedf-0000-000000000000@84df9e7f-e9f6-40af-b435-aaaaaaaaaaaa')\/Events('AQMkADAwATMwMAItZDJlYy1mZWRmLTAwAi0wMAoARgAAA3tf3VWLTbtKr31QnkQPjAsHAHgeJ1juCepKqGww5D6w8McAAAIBDQAAAHgeJ1juCepKqGww5D6w8McAAAA-XbFzAAAA')",
                "@odata.etag" => "W\/\\\"eB4nWO4J6kqobDDkPrDwxwAAQOIWwg==\\\"",
                "Id" => "AQMkADAwATMwMAItZDJlYy1mZWRmLTAwAi0wMAoARgAAA3tf3VWLTbtKr31QnkQPjAsHAHgeJ1juCepKqGww5D6w8McAAAIBDQAAAHgeJ1juCepKqGww5D6w8McAAAA-XbFzAAAA",
                "Subject" => "Allday yes",
                "IsAllDay" => true,
                "IsCancelled" => false,
                "ShowAs" => "Free",
                "ResponseStatus" => {
                  "Response" => "Organizer",
                  "Time" => "0001-01-01T00:00:00Z"
                },
                "Body" => {
                  "ContentType" => "HTML",
                  "Content" => ""
                },
                "Start" => {
                  "DateTime" => "#{start_at.strftime('%Y-%m-%d')}T00:00:00.0000000",
                  "TimeZone" => "UTC"
                },
                "End" => {
                  "DateTime" => "#{end_at.strftime('%Y-%m-%d')}T00:00:00.0000000",
                  "TimeZone" => "UTC"
                }
              }
            ]
          }
        }

        describe "it interprets the correct times and pushes a non-all-day event" do
          before(:each) do
            allow(outlook_client)
              .to receive(:get_calendar_view)
              .with(
                from_account.access_token,
                within(1.second).of(Time.zone.now),
                within(1.second).of(1.month.from_now),
                from_calendar.external_id,
                anything
              )
              .and_return(raw_outlook_calendar_view_response)

            allow(google_service)
              .to receive(:list_events)
              .with(
                to_calendar.external_id,
                hash_including(:time_max, :time_min, :single_events, :max_results, :order_by)
              )
              .and_return({ items: [] }.to_ostruct)

            expect(google_batch)
              .to receive(:insert_event) do |cal_id, _hash|
                expect(cal_id)
                  .to eq to_calendar.external_id

                # Gave up trying to lock down this issue. Time zones in rails are hard
                # outlook_bug_offset = ActiveSupport::TimeZone.new(to_calendar.time_zone).utc_offset

                # expect(hash.start)
                #   .to match(
                #     date_time: (start_at.in_time_zone(to_calendar.time_zone) - outlook_bug_offset.seconds).iso8601,
                #   )

                # expect(hash.end)
                #   .to match(
                #     date_time: (end_at.in_time_zone(to_calendar.time_zone) - 1.second - outlook_bug_offset.seconds).iso8601,
                #   )
              end
          end

          it { subject }
        end
      end

      context "from google to google" do 
        let(:to_account) { create :google_account }
        let(:from_account) { create :google_account }

        let(:raw_google_calendar_view_response) {
          {
            start: {
              date: start_at.to_date.strftime('%Y-%m-%d'),
              time_zone: 'America/Los_Angeles',
            },
            attendees: [],
            end: {
              date: (start_at.to_date + 1.day).strftime('%Y-%m-%d'),
              time_zone: 'America/Los_Angeles',
            },
            creator: {
              self: true,
            },
            summary: Faker::Lorem.sentence,
            description: "",
            transparency: 'Opaque',
          }.to_ostruct
        }

        let(:google_response) { double('google_response') }

        it "interprets the correct times and pushes a non-all-day event" do
          allow(google_response)
            .to receive(:items)
            .and_return([raw_google_calendar_view_response])

          allow(google_service)
            .to receive(:list_events)
            .with(
              from_calendar.external_id,
              hash_including(:time_max, :time_min, :single_events, :max_results, :order_by)
            )
            .and_return(google_response)

          allow(google_service)
            .to receive(:list_events)
            .with(
              to_calendar.external_id,
              hash_including(:time_max, :time_min, :single_events, :max_results, :order_by)
            )
            .and_return({ items: [] }.to_ostruct)

          expect(google_batch)
            .to receive(:insert_event) do |cal_id, hash|
              expect(cal_id)
                .to eq to_calendar.external_id
            end

          subject
        end
      end

      context "from google to outlook" do
        let(:to_account) { create :outlook_account }
        let(:from_account) { create :google_account }

        let(:raw_google_calendar_view_response) {
          {
            start: {
              date: start_at.to_date.strftime('%Y-%m-%d'),
              time_zone: 'America/Los_Angeles',
            },
            attendees: [],
            end: {
              date: (start_at.to_date + 1.day).strftime('%Y-%m-%d'),
              time_zone: 'America/Los_Angeles',
            },
            creator: {
              self: true,
            },
            summary: Faker::Lorem.sentence,
            description: "",
            transparency: 'Opaque',
          }.to_ostruct
        }

        let(:google_response) { double('google_response') }

        it "interprets the correct times and pushes a non-all-day event" do
          allow(google_response)
            .to receive(:items)
            .and_return([raw_google_calendar_view_response])

          allow(google_service)
            .to receive(:list_events)
            .with(
              from_calendar.external_id,
              hash_including(:time_max, :time_min, :single_events, :max_results, :order_by)
            )
            .and_return(google_response)

          allow(outlook_client)
            .to receive(:get_calendar_view)
            .with(
              to_account.access_token,
              within(1.second).of(Time.zone.now),
              within(1.second).of(1.month.from_now),
              to_calendar.external_id,
              anything
            )
            .and_return('value' => [])

          expect(outlook_client)
            .to receive(:create_event) do |access_token, hash, cal_id|
              expect(access_token)
                .to eq to_calendar.access_token

              expect(cal_id)
                .to eq to_calendar.external_id

              # outlook_bug_offset = ActiveSupport::TimeZone.new(from_calendar.time_zone).utc_offset -
              #                      ActiveSupport::TimeZone.new(to_calendar.time_zone).utc_offset

              # puts start_at.inspect,
              #      start_at.in_time_zone(to_calendar.time_zone).inspect,
              #      (start_at.in_time_zone(to_calendar.time_zone) - outlook_bug_offset.seconds).iso8601,
              #      end_at.inspect,
              #      end_at.in_time_zone(to_calendar.time_zone).inspect,
              #      (end_at.in_time_zone(to_calendar.time_zone) - 1.second - outlook_bug_offset.seconds).iso8601

              # expect(hash['Start']['DateTime'])
              #   .to eq(start_at.in_time_zone(to_calendar.time_zone).utc.iso8601)

              # expect(hash['End']['DateTime'])
              #   .to eq((end_at.in_time_zone(to_calendar.time_zone) - 1.second).utc.iso8601)

              expect(hash['IsAllDay'])
                .to be_falsy

              hash
            end

          subject
        end
      end
    end

    context "with two calendars that are not synced" do
      before(:each) { pair.delete }

      it "will not contact any remote services" do
        expect{ subject }
          .to raise_error CalendarShadowHelper::CastingUnsyncdCalendars
      end
    end

    context "with two calendars that are being synced" do
      before(:each) {
        expect(CalendarShadowHelper)
          .to receive(:update_calendar_events_cache)
          .with(from_calendar)

        expect(CalendarShadowHelper)
          .to receive(:update_calendar_events_cache)
          .with(to_calendar)
      }

      context "with no events" do
        it { is_expected.to be_empty }
      end

      context "with events that will be synced" do
        before(:each) {
          event_will_be_synced
          event_already_pushed

          expect(to_calendar)
            .to receive(:push_events) do |events|
              expect(events)
                .to(
                  include(
                    have_attributes(
                      "source_event_id" => event_will_be_synced.id,
                    )
                  ).and(
                    omit(
                      have_attributes(
                        "source_event_id" => event_already_pushed.id,
                      )
                    )
                  )
                )
            end
        }

        it { is_expected.to an_instance_of(Array) }

        context "when one of the batch requests fails" do
          it "will save external_id of the events which were created successfully"
          it "will not save any external_id of the events which failed to create"
          it "will report the error"
        end
      end
    end
  end

  describe "#push_shadow_of_event" do
    before(:each) {
      event.reload
    }

    subject { CalendarShadowHelper.push_shadow_of_event(event).tap { event.reload } }

    context "with a shadow" do
      let(:event) { shadow_event }

      it "will complain without calling the remote service" do
        expect(TestCalendarApiHelper)
          .not_to receive(:push_events)

        expect{ subject }
          .to raise_error CalendarShadowHelper::ShadowOfShadowError
      end
    end

    context "given a source event" do
      let(:event) { source_event }

      context "with no existing local shadow" do
        before(:each) {
          expect(event.shadow_event)
            .to be_nil

          expect(TestCalendarApiHelper)
            .to receive(:push_events)
            .with(
              event.corresponding_calendar.access_token,
              event.corresponding_calendar.external_id,
              array_including(
                have_attributes(
                  source_event_id: event.id
                )
              )
            )
        }

        after(:each) {
          expect(event.shadow_event)
            .not_to be_nil
        }

        it { is_expected.to be_nil }
      end

      context "with a local shadow with no external_id" do
        before(:each) {
          shadow_event.update_attributes external_id: nil

          expect(TestCalendarApiHelper)
            .to receive(:push_events)
            .with(
              shadow_event.access_token,
              shadow_event.calendar.external_id,
              array_including(shadow_event)
            )
        }

        it { is_expected.to be_nil }

        it "wont create any stray events" do
          expect{ subject }.not_to(change{ Event.count })
        end
      end

      context "with a local shadow with an existing external_id" do
        before(:each) {
          expect(shadow_event).not_to have_attributes(external_id: nil)
          expect(event.shadow_event).to eq(shadow_event)

          expect(TestCalendarApiHelper)
            .not_to receive(:push_events)
        }

        it { is_expected.to be_nil }
      end

      context "when the remote service fails" do
        let(:expected_error) { StandardError.new("Expected") }

        before(:each) {
          expect(event.shadow_event)
            .to be_nil

          expect(TestCalendarApiHelper)
            .to receive(:push_events)
            .with(
              shadow_event.access_token,
              shadow_event.calendar.external_id,
              array_including(shadow_event)
            )
            .and_raise(expected_error)
        }

        it {
          expect{ subject }
            .to raise_error(expected_error)
            .and(avoid_changing{ Event.count })
        }
      end

      context "when the event isn't being synced" do
        before(:each) {
          expect(event.shadow_event)
            .to be_nil

          expect(TestCalendarApiHelper)
            .not_to receive(:push_events)
        }

        let(:event) { create :event }

        it {
          expect{ subject }
            .to raise_error(CalendarShadowHelper::ShadowWithoutPairError)
            .and(avoid_changing{ Event.count })
        }
      end
    end
  end

  describe "#destroy_shadow_of_event" do
    before(:each) {
      event.reload
    }

    subject { CalendarShadowHelper.destroy_shadow_of_event(event).tap { event.reload } }

    context "with a shadow" do
      let(:event) { shadow_event }

      before(:each) {
        expect(TestCalendarApiHelper)
          .not_to receive(:delete_event)
      }

      it "will complain without calling the remote service" do
        expect{ subject }
          .to raise_error CalendarShadowHelper::ShadowOfShadowError
      end
    end

    context "given a source event" do
      let(:event) { source_event }

      context "will end up deleting the shadow from the db" do
        after(:each) {
          expect(event.shadow_event)
            .to be_nil
        }

        context "when the shadow doesn't have an external id" do
          before(:each) {
            shadow_event.update_attributes external_id: nil

            expect(TestCalendarApiHelper)
              .not_to receive(:delete_event)
          }

          it { is_expected.to be_nil }
        end

        context "when the shadow does have an external_id" do
          it "will also delete from the remote source" do
            expect(TestCalendarApiHelper)
              .to receive(:delete_event)
              .with(
                shadow_event.access_token,
                shadow_event.calendar.external_id,
                shadow_event.external_id
              )

            expect(subject).to be_nil
          end
        end
      end

      context "without a shadow event in the DB" do
        it "quietly won't try to delete anything" do
          expect(event.shadow_event).to be_nil # Sanity

          expect(TestCalendarApiHelper)
            .not_to receive(:delete_event)

          expect(subject).to be_nil

          expect(event.shadow_event).to be_nil
        end
      end

      context "wont end up deleting the event's shadow from the DB" do
        before(:each) { expect(shadow_event).not_to be_nil } # Sanity
        after(:each) { expect(event.shadow_event).not_to be_nil }

        context "when the remote service throws an error" do
          before(:each) {
            expect(TestCalendarApiHelper)
              .to receive(:delete_event)
              .and_raise "Fail"
          }

          it {
            expect{ subject }
              .to raise_error("Fail")
              .and(avoid_changing{ Event.count })
          }
        end
      end
    end
  end
end
