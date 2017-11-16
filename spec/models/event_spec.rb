# frozen_string_literal: true

require "rails_helper"

describe "Event", type: :model do
  let(:new_event) { FactoryBot.build :event }
  let(:shadow) { FactoryBot.create :event, :is_shadow }

  describe "#toggle_shadow" do
    subject { event_to_test.send(:toggle_shadow) }

    context "on an unsynced event" do
      let(:event_to_test) { create :event }

      before(:each) {
        expect(GoogleCalendarApiHelper).not_to receive(:create_events)
        expect(CalendarShadowHelper).not_to receive(:shadow_of_event)
      }

      it { is_expected.to be true }

      after(:each) {
        event_to_test.reload
        expect(event_to_test.shadow_event).to be_nil
      }
    end

    context "on a synced event" do
      let(:pair) { FactoryBot.create :sync_pair }
      let(:source) { FactoryBot.create :event, calendar_id: pair.from_calendar_id }
      let(:shadow) { FactoryBot.create :event, :is_shadow, calendar_id: pair.to_calendar_id, source_event_id: source.id }

      context "when is_attending is changing from false to true" do
        before(:each) {
          Event.where(id: event_to_test).update_all is_attending: false # Includes a save to clear callbacks
          event_to_test.reload
        }
        before(:each) { event_to_test.is_attending = true } # Leaves unsaved, so callbacks are called

        context "when the event is a shadow" do
          let(:event_to_test) { shadow }

          before(:each) {
            expect(GoogleCalendarApiHelper).not_to receive(:create_events)
            expect(CalendarShadowHelper).not_to receive(:shadow_of_event)
          }

          it { is_expected.to be true }
        end

        context "and the event is a proper source event" do
          let(:event_to_test) { source }

          context "and a shadow event exists in the DB" do
            before(:each) { shadow }
            before(:each) { expect(event_to_test.shadow_event).not_to be_nil } # Sanity

            it "won't try to create the remote calendar event" do
              expect(CalendarShadowHelper)
                .not_to receive(:create_shadow_of_event)
                .with(event_to_test)

              expect(subject).to be true
            end
          end

          context "but the shadow event does not yet exist in the DB" do
            before(:each) { expect(event_to_test.shadow_event).to be_nil } # Sanity

            context "and the remote calendar request fails" do
              before(:each) {
                expect(CalendarShadowHelper)
                  .to receive(:create_shadow_of_event)
                  .with(event_to_test)
                  .and_raise(CalendarShadowHelper::ShadowHelperError, "failure")
              }

              it { is_expected.to be true }
            end

            context "and the remote calendar request succeeds" do
              before(:each) {
                expect(CalendarShadowHelper)
                  .to receive(:create_shadow_of_event)
                  .with(event_to_test) do
                    shadow
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
          let(:event_to_test) { shadow }

          before(:each) {
            expect(GoogleCalendarApiHelper).not_to receive(:create_events)
            expect(CalendarShadowHelper).not_to receive(:shadow_of_event)
          }

          it { is_expected.to be true }
        end

        context "and the event is a proper source event" do
          let(:event_to_test) { source }

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
            before(:each) { shadow }
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
                    shadow
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
      allow(GoogleCalendarApiHelper)
        .to receive(:move_event)
        .and_return(true)
    end

    context "on a shadow event" do
      let(:event) { create :event, :is_shadow }

      it "pushes dates to the source event" do
        expect(GoogleCalendarApiHelper)
          .to receive(:move_event) do |access_token, calendar_id, event_id, start_at, end_at|
          expect(access_token).to eq event.source_event.access_token
          expect(calendar_id).to eq event.source_event.calendar.external_id
          expect(event_id).to eq event.source_event.external_id
          expect(start_at).to eq event.start_at
          expect(end_at).to eq event.end_at
        end
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
        expect(GoogleCalendarApiHelper)
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
      let(:event) { create :event, :has_shadow }

      it "pushes dates to the shadow event" do
        expect(GoogleCalendarApiHelper)
          .to receive(:move_event) do |access_token, calendar_id, event_id, start_at, end_at|
          expect(access_token).to eq event.shadow_event.access_token
          expect(calendar_id).to eq event.shadow_event.calendar.external_id
          expect(event_id).to eq event.shadow_event.external_id
          expect(start_at).to eq event.start_at
          expect(end_at).to eq event.end_at
        end
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
        expect(GoogleCalendarApiHelper)
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
      let(:event) { create :event }

      it "does not touch the api" do
        expect(GoogleCalendarApiHelper)
          .not_to receive(:move_event)
        subject
      end
    end
  end
end
