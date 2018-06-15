# frozen_string_literal: true

require "rails_helper"

describe CalendarShadowHelper do
  let(:pair) { create :sync_pair }
  let(:source_event) { create :event, calendar_id: pair.from_calendar_id }
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
          expect(to_calendar)
            .to receive(:push_events)
            .with(
              array_including(
                have_attributes(
                  "source_event_id" => event_will_be_synced.id,
                )
              )
            )
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
              shadow_event.access_token,
              shadow_event.calendar.external_id,
              array_including(shadow_event)
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
