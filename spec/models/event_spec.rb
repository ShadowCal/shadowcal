# frozen_string_literal: true

require "rails_helper"

def build_tests_outside_work_hours
  let(:calendar) { create :calendar, time_zone: time_zone }
  let(:original_utc) { ActiveSupport::TimeZone.new(time_zone).parse('00:00:01').utc }
  let(:saturday) { original_utc - original_utc.wday.days - 1.day }
  let(:sunday) { original_utc - original_utc.wday.days }
  let(:tuesday) { original_utc - original_utc.wday.days + 2.days }
  let(:friday) { original_utc - original_utc.wday.days - 2.day }
  # let(:start_of_day) defined in contexts, below
  let(:end_of_day) { start_of_day + 23.hours + 59.minutes }
  let(:before_8_am) { start_of_day + 7.hours + 59.minutes }
  let(:after_7_pm) { start_of_day + 19.hours + 1.minutes }
  let(:midday) { start_of_day + 12.hours }
  let(:tomorrow_start_of_day) { start_of_day + 1.day }
  let(:tomorrow_end_of_day) { end_of_day + 1.day }
  let(:tomorrow_before_8_am) { before_8_am + 1.day }
  let(:tomorrow_after_7_pm) { after_7_pm + 1.day }
  let(:tomorrow_midday) { midday + 1.day }

  context "tuesday" do
    let(:start_of_day) { tuesday }

    context "starting and ending before 8am" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am - 10.minutes, end_at: before_8_am }

      it { is_expected.to be true }
    end

    context "starting and ending after 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: after_7_pm + 10.minutes }

      it { is_expected.to be true }
    end

    context "starting before 8am, ending before 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: midday }

      it { is_expected.to be false }
    end

    context "starting before 8am, ending before 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: tomorrow_before_8_am }

      it { is_expected.to be false }
    end

    context "starting before 8am, ending after 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: after_7_pm }

      it { is_expected.to be false }
    end

    context "starting after 6pm, ending before 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_before_8_am }

      it { is_expected.to be true }
    end

    context "starting after 6pm, ending after 6pm the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_after_7_pm }

      it { is_expected.to be false }
    end

    context "all day today" do
      let(:event) { create :event, calendar: calendar, start_at: start_of_day, end_at: end_of_day }

      it { is_expected.to be false }
    end

    context "all day tomorrow" do
      let(:event) { create :event, calendar: calendar, start_at: tomorrow_start_of_day, end_at: tomorrow_end_of_day }

      it { is_expected.to be false }
    end
  end

  context "saturday" do
    let(:start_of_day) { saturday }

    context "starting and ending before 8am" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am - 10.minutes, end_at: before_8_am }

      it { is_expected.to be true }
    end

    context "starting and ending after 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: after_7_pm + 10.minutes }

      it { is_expected.to be true }
    end

    context "starting before 8am, ending before 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: midday }

      it { is_expected.to be true }
    end

    context "starting before 8am, ending before 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: tomorrow_before_8_am }

      it { is_expected.to be true }
    end

    context "starting before 8am, ending after 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: after_7_pm }

      it { is_expected.to be true }
    end

    context "starting after 6pm, ending before 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_before_8_am }

      it { is_expected.to be true }
    end

    context "starting after 6pm, ending after 6pm the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_after_7_pm }

      it { is_expected.to be true }
    end

    context "all day today" do
      let(:event) { create :event, calendar: calendar, start_at: start_of_day, end_at: end_of_day }

      it { is_expected.to be true }
    end

    context "all day tomorrow" do
      let(:event) { create :event, calendar: calendar, start_at: tomorrow_start_of_day, end_at: tomorrow_end_of_day }

      it { is_expected.to be true }
    end
  end

  context "sunday" do
    let(:start_of_day) { sunday }

    context "starting and ending before 8am" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am - 10.minutes, end_at: before_8_am }

      it { is_expected.to be true }
    end

    context "starting and ending after 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: after_7_pm + 10.minutes }

      it { is_expected.to be true }
    end

    context "starting before 8am, ending before 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: midday }

      it { is_expected.to be true }
    end

    context "starting before 8am, ending before 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: tomorrow_before_8_am }

      it { is_expected.to be true }
    end

    context "starting before 8am, ending after 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: after_7_pm }

      it { is_expected.to be true }
    end

    context "starting after 6pm, ending before 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_before_8_am }

      it { is_expected.to be true }
    end

    context "starting after 6pm, ending after 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_midday }

      it { is_expected.to be false }
    end

    context "starting after 6pm, ending after 6pm the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_after_7_pm }

      it { is_expected.to be false }
    end

    context "all day today" do
      let(:event) { create :event, calendar: calendar, start_at: start_of_day, end_at: end_of_day }

      it { is_expected.to be true }
    end

    context "all day tomorrow" do
      let(:event) { create :event, calendar: calendar, start_at: tomorrow_start_of_day, end_at: tomorrow_end_of_day }

      it { is_expected.to be false }
    end
  end

  context "friday" do
    let(:start_of_day) { friday }

    context "starting and ending before 8am" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am - 10.minutes, end_at: before_8_am }

      it { is_expected.to be true }
    end

    context "starting and ending after 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: after_7_pm + 10.minutes }

      it { is_expected.to be true }
    end

    context "starting before 8am, ending before 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: midday }

      it { is_expected.to be false }
    end

    context "starting before 8am, ending before 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: tomorrow_before_8_am }

      it { is_expected.to be false }
    end

    context "starting before 8am, ending after 6pm" do
      let(:event) { create :event, calendar: calendar, start_at: before_8_am, end_at: after_7_pm }

      it { is_expected.to be false }
    end

    context "starting after 6pm, ending before 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_before_8_am }

      it { is_expected.to be true }
    end

    context "starting after 6pm, ending after 8am the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_midday }

      it { is_expected.to be true }
    end

    context "starting after 6pm, ending after 6pm the next day" do
      let(:event) { create :event, calendar: calendar, start_at: after_7_pm, end_at: tomorrow_after_7_pm }

      it { is_expected.to be true }
    end

    context "all day today" do
      let(:event) { create :event, calendar: calendar, start_at: start_of_day, end_at: end_of_day }

      it { is_expected.to be false }
    end

    context "all day tomorrow" do
      let(:event) { create :event, calendar: calendar, start_at: tomorrow_start_of_day, end_at: tomorrow_end_of_day }

      it { is_expected.to be true }
    end
  end
end

describe "Event", type: :model do
  let(:new_event) { build :event }

  let(:pair) { create :sync_pair }
  let(:source_event) { create :syncable_event, calendar_id: pair.from_calendar_id }
  let(:shadow_event) { create :event, :is_shadow, calendar_id: pair.to_calendar_id, source_event_id: source_event.id }

  describe "#outside_work_hours" do
    subject { event.outside_work_hours }

    context "Time Zone: Pacific" do
      let(:time_zone) { 'America/Los_Angeles' }

      build_tests_outside_work_hours
    end

    context "Time Zone: Eastern" do
      let(:time_zone) { 'America/New_York' }

      build_tests_outside_work_hours
    end

    context "Time Zone: UTC" do
      let(:time_zone) { 'UTC' }

      build_tests_outside_work_hours
    end
  end

  describe "#corresponding_calendar" do
    subject { event.corresponding_calendar }
    context "when event is not synced" do
      let(:event) { create :event }

      it { is_expected.to be_nil }
    end

    context "when event is synced" do
      context "and is a shadow" do
        let(:event) { shadow_event }

        it { is_expected.to eq source_event.calendar }
      end

      context "and is a source" do
        let(:event) { shadow_event.source_event }

        it { is_expected.to eq shadow_event.calendar }
      end
    end
  end

  describe "#toggle_shadow" do
    subject { event_to_test.send(:toggle_shadow) }

    context "on an unsynced event" do
      let(:event_to_test) { create :event }

      before(:each) {
        expect(CalendarApiHelper::Google).not_to receive(:push_events)
        expect(CalendarShadowHelper).not_to receive(:shadow_of_event)
      }

      it { is_expected.to be true }

      after(:each) {
        event_to_test.reload
        expect(event_to_test.shadow_event).to be_nil
      }
    end

    context "on a synced event" do
      context "when is_attending is changing from false to true" do
        before(:each) {
          Event.where(id: event_to_test).update_all is_attending: false # Includes a save to clear callbacks
          event_to_test.reload
        }
        before(:each) { event_to_test.is_attending = true } # Leaves unsaved, so callbacks are called

        context "when the event is a shadow" do
          let(:event_to_test) { shadow_event }

          before(:each) {
            expect(CalendarApiHelper::Google).not_to receive(:push_events)
            expect(CalendarShadowHelper).not_to receive(:shadow_of_event)
          }

          it { is_expected.to be true }
        end

        context "and the event is a proper source event" do
          let(:event_to_test) { source_event }

          context "and a shadow event exists in the DB" do
            before(:each) { shadow_event }
            before(:each) { expect(event_to_test.shadow_event).not_to be_nil } # Sanity

            it "won't try to create the remote calendar event" do
              expect(CalendarShadowHelper)
                .not_to receive(:push_shadow_of_event)
                .with(event_to_test)

              expect(subject).to be true
            end
          end

          context "but the shadow event does not yet exist in the DB" do
            before(:each) { expect(event_to_test.shadow_event).to be_nil } # Sanity

            context "and the remote calendar request fails" do
              before(:each) {
                expect(CalendarShadowHelper)
                  .to receive(:push_shadow_of_event)
                  .with(event_to_test)
                  .and_raise(CalendarShadowHelper::ShadowHelperError, "failure")
              }

              it { is_expected.to be true }
            end

            context "and the remote calendar request succeeds" do
              before(:each) {
                expect(CalendarShadowHelper)
                  .to receive(:push_shadow_of_event)
                  .with(event_to_test) do
                    shadow_event
                  end
              }

              it { is_expected.to be true }
            end
          end
        end
      end

      context "when is_attending is changing from true to false" do
        before(:each) {
          Event.where(id: event_to_test).update_all is_attending: true # Includes a save to clear callbacks
          event_to_test.reload
        }
        before(:each) { event_to_test.is_attending = false } # Leaves unsaved, so callbacks are called

        context "and the event is the shadow" do
          let(:event_to_test) { shadow_event }

          before(:each) {
            expect(CalendarApiHelper::Google).not_to receive(:push_events)
            expect(CalendarShadowHelper).not_to receive(:shadow_of_event)
          }

          it { is_expected.to be true }
        end

        context "and the event is a proper source event" do
          let(:event_to_test) { source_event }

          context "but a shadow event already doesn't exist in the DB" do
            before(:each) { expect(event_to_test.shadow_event).to be_nil } # Sanity

            it "won't try to destroy the remote calendar event" do
              expect(CalendarShadowHelper)
                .not_to receive(:destroy_shadow_of_event)
                .with(event_to_test)

              expect(subject).to be true
            end
          end

          context "and the shadow event already exists in the DB" do
            before(:each) { shadow_event }
            before(:each) { expect(event_to_test.shadow_event).not_to be_nil } # Sanity

            context "and the remote calendar request fails" do
              before(:each) {
                expect(CalendarShadowHelper)
                  .to receive(:destroy_shadow_of_event)
                  .with(event_to_test)
                  .and_raise(CalendarShadowHelper::ShadowHelperError, "failure")
              }

              it { is_expected.to be true }
            end

            context "and the remote calendar request succeeds" do
              before(:each) {
                expect(CalendarShadowHelper)
                  .to receive(:destroy_shadow_of_event)
                  .with(event_to_test) do
                    shadow_event
                  end
              }

              it { is_expected.to be true }
            end
          end
        end
      end
    end
  end

  describe "#moved?" do
    let(:event) { create :event }
    subject { event.moved? }

    it "returns true if start date was changed" do
      event.start_at = event.start_at + 1.minute
      is_expected.to be_truthy
    end

    it "returns true if end date was changed" do
      event.end_at = event.end_at + 1.minute
      is_expected.to be_truthy
    end

    it "returns false if neither has changed" do
      event.name = "Not #{event.name}"
      is_expected.to be_falsy
    end

    it "returns false if the object is new" do
      new_event.start_at = new_event.start_at + 1.minute
      is_expected.to be_falsy
    end
  end

  describe "#corresponding_event" do
    subject { event.corresponding_event }

    context "shadow event" do
      let(:event) { create :event, :is_shadow }

      it "returns source_event" do
        expect(subject).to eq event.source_event
      end
    end

    context "source event" do
      let(:event) { create :event, :has_shadow }

      it "returns shadow_event.id" do
        expect(subject).to eq event.shadow_event
      end
    end

    context "no corresponding event" do
      let(:event) { create :event }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#push_date_changes_to_corresponding_event" do
    subject {
      event.send(:push_date_changes_to_corresponding_event).tap do
        event.reload
      end
    }

    before :each do
      allow(TestCalendarApiHelper)
        .to receive(:move_event)
        .and_return(true)
    end

    context "on a shadow event" do
      let(:event) { create :syncable_event, :is_shadow }

      it "pushes dates to the source event" do
        expect(TestCalendarApiHelper)
          .to receive(:move_event)
          .with(
            event.source_event.access_token,
            event.source_event.calendar.external_id,
            event.source_event.external_id,
            event.start_at,
            event.end_at
          )
        subject
      end

      it "updates the source event in db" do
        expect(event.source_event.start_at).not_to eq event.start_at
        expect(event.source_event.end_at).not_to eq event.end_at
        subject
        expect(event.source_event.start_at).to eq event.start_at
        expect(event.source_event.end_at).to eq event.end_at
      end

      it "doesn't update db if source event fails to push" do
        expect(TestCalendarApiHelper)
          .to receive(:move_event)
          .and_raise "Fail"

        expect(event.source_event.start_at).not_to eq event.start_at
        expect(event.source_event.end_at).not_to eq event.end_at
        expect{ subject }.to raise_error("Fail")
        expect(event.source_event.start_at).not_to eq event.start_at
        expect(event.source_event.end_at).not_to eq event.end_at
      end
    end

    context "on a source event" do
      let(:event) { create :syncable_event, :has_shadow }

      it "pushes dates to the shadow event" do
        expect(TestCalendarApiHelper)
          .to receive(:move_event)
          .with(
            event.shadow_event.access_token,
            event.shadow_event.calendar.external_id,
            event.shadow_event.external_id,
            event.start_at,
            event.end_at
          )
        subject
      end

      it "updates the shadow in db" do
        expect(event.shadow_event.start_at).not_to eq event.start_at
        expect(event.shadow_event.end_at).not_to eq event.end_at
        subject
        expect(event.shadow_event.start_at).to eq event.start_at
        expect(event.shadow_event.end_at).to eq event.end_at
      end

      it "doesn't update db if shadow event fails to push" do
        expect(TestCalendarApiHelper)
          .to receive(:move_event)
          .and_raise "Fail"

        expect(event.shadow_event.start_at).not_to eq event.start_at
        expect(event.shadow_event.end_at).not_to eq event.end_at
        expect{ subject }.to raise_error("Fail")
        expect(event.shadow_event.start_at).not_to eq event.start_at
        expect(event.shadow_event.end_at).not_to eq event.end_at
      end
    end

    context "on an event with no corresponding event" do
      let(:event) { create :syncable_event }

      it "does not touch the api" do
        expect(TestCalendarApiHelper)
          .not_to receive(:move_event)
        subject
      end
    end
  end
end
