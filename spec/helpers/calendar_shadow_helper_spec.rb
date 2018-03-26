# frozen_string_literal: true

require "rails_helper"

describe CalendarShadowHelper do
  let(:pair) { create :sync_pair }
  let(:source_event) { create :event, calendar_id: pair.from_calendar_id }
  let(:shadow_event) { create :event, :is_shadow, calendar_id: pair.to_calendar_id, source_event_id: source_event.id }

  describe "#cast_from_to" do
    let(:pair) { create :sync_pair }
    let(:from_calendar) { pair.from_calendar }
    let(:to_calendar) { pair.to_calendar }
    let(:event_not_attending) { create :syncable_event, name: "not attending", calendar: from_calendar, is_attending: false }
    let(:event_already_pushed) { create :syncable_event, :has_shadow, name: "already_pushed", calendar: from_calendar }
    let(:event_on_destination_calendar) { create :syncable_event, name: "on destination calendar", calendar: to_calendar }
    let(:event_will_be_synced) { create :syncable_event, name: "will sync", calendar: from_calendar }
    let(:event_on_weekend) { create :syncable_event, :weekend, name: "weekend" }
    let(:event_after_work_hours) { create :syncable_event, :after_work_hours, name: "after hours" }

    subject { CalendarShadowHelper.cast_from_to(from_calendar, to_calendar) }

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
        it { is_expected.to be_nil }
      end

      context "with events that won't be synced" do
        before(:each) {
          event_not_attending
          event_already_pushed
          event_on_destination_calendar
          # event_on_weekend
          # event_after_work_hours

          expect(GoogleCalendarApiHelper)
            .not_to receive(:push_events)
        }

        it { is_expected.to be_nil }
      end

      context "with events that will be synced" do
        before(:each) {
          event_will_be_synced

          expect(GoogleCalendarApiHelper)
            .to receive(:push_events) do |access_token, external_id, shadows|
              expect(access_token)
                .to eq to_calendar.access_token

              expect(external_id)
                .to eq to_calendar.external_id

              expect(shadows.map(&:attributes))
                .to include(
                  hash_including(
                    "source_event_id" => event_will_be_synced.id,
                  )
                )
            end
        }

        it { is_expected.to be_nil }

        context "when one of the batch requests fails" do
          it "will save external_id of the events which were created successfully"
          it "will not save any external_id of the events which failed to create"
          it "will report the error"
        end
      end
    end
  end

  describe "#push_shadow_of_event" do
    subject { CalendarShadowHelper.push_shadow_of_event(event).tap { event.reload } }

    context "with a shadow" do
      let(:event) { shadow_event }

      before(:each) {
        expect(GoogleCalendarApiHelper)
          .not_to receive(:push_event)
      }

      it "will complain without calling the remote service" do
        expect{ subject }
          .to raise_error CalendarShadowHelper::ShadowHelperError
      end
    end

    context "given a source event" do
      let(:event) { source_event }

      context "with no existing local shadow" do
        before(:each) {
          expect(event.shadow_event)
            .to be_nil

          expect(GoogleCalendarApiHelper)
            .to receive(:push_event)
            .with(
              shadow_event.access_token,
              shadow_event.calendar.external_id,
              shadow_event
            )
        }

        after(:each) {
          expect(event.shadow_event)
            .not_to be_nil
        }

        it { is_expected.to be true }
      end

      context "with a local shadow with no external_id" do
        before(:each) { shadow_event.update_attributes external_id: nil }

        before(:each) {
          expect(GoogleCalendarApiHelper)
            .to receive(:push_event)
            .with(
              shadow_event.access_token,
              shadow_event.calendar.external_id,
              shadow_event
            )
        }

        it { is_expected.to be true }

        it "wont create any stray events" do
          expect{ subject }.not_to(change{ Event.count })
        end
      end

      context "with a local shadow with an existing external_id" do
        before(:each) {
          shadow_event

          expect(GoogleCalendarApiHelper)
            .not_to receive(:push_event)
        }

        it { is_expected.to be true }
      end

      context "when the remote service fails" do
        before(:each) {
          expect(event.shadow_event)
            .to be_nil

          expect(GoogleCalendarApiHelper)
            .to receive(:push_event)
            .with(
              shadow_event.access_token,
              shadow_event.calendar.external_id,
              shadow_event
            )
            .and_raise(CalendarShadowHelper::ShadowHelperError)
        }

        it { expect{ subject }.not_to(change{ Event.count }) }

        it { is_expected.to be true }
      end

      context "when the event isn't being synced" do
        before(:each) {
          expect(event.shadow_event)
            .to be_nil

          expect(GoogleCalendarApiHelper)
            .not_to receive(:push_event)
        }

        let(:event) { create :event }

        it { is_expected.to be true }
      end
    end
  end

  describe "#destroy_shadow_of_event" do
    subject { CalendarShadowHelper.destroy_shadow_of_event(event).tap { event.reload } }

    context "with a shadow" do
      let(:event) { shadow_event }

      before(:each) {
        expect(GoogleCalendarApiHelper)
          .not_to receive(:delete_event)
      }

      it "will complain without calling the remote service" do
        expect{ subject }
          .to raise_error CalendarShadowHelper::ShadowHelperError
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

            expect(GoogleCalendarApiHelper)
              .not_to receive(:delete_event)
          }

          it { is_expected.to be true }
        end

        context "when the shadow does have an external_id" do
          it "will also delete from the remote source" do
            expect(GoogleCalendarApiHelper)
              .to receive(:delete_event)
              .with(
                shadow_event.access_token,
                shadow_event.calendar.external_id,
                shadow_event.external_id
              )

            expect(subject).to be true
          end
        end
      end

      context "without a shadow event in the DB" do
        it "quietly won't try to delete anything" do
          expect(event.shadow_event).to be_nil # Sanity

          expect(GoogleCalendarApiHelper)
            .not_to receive(:delete_event)

          expect(subject).to be true

          expect(event.shadow_event).to be_nil
        end
      end

      context "wont end up deleting the event's shadow from the DB" do
        before(:each) { expect(shadow_event).not_to be_nil } # Sanity
        after(:each) { expect(event.shadow_event).not_to be_nil }

        context "when the remote service throws an error" do
          before(:each) {
            expect(GoogleCalendarApiHelper)
              .to receive(:delete_event)
              .and_raise "Fail"
          }

          it { is_expected.to be true }
        end
      end
    end
  end
end
