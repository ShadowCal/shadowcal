# frozen_string_literal: true

require "rails_helper"

describe CalendarShadowHelper do
  let(:pair) { create :sync_pair }
  let(:source_event) { create :event, calendar_id: pair.from_calendar_id }
  let(:shadow_event) { create :event, :is_shadow, calendar_id: pair.to_calendar_id, source_event_id: source_event.id }

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
          expect{subject}.not_to change{Event.count}
        end
      end

      context" with a local shadow with an existing external_id" do
        before(:each) {
          shadow_event

          expect(GoogleCalendarApiHelper)
            .not_to receive(:push_event)
        }

        it { is_expected.to be true }
      end

      context "won't create anything when the remote service fails" do
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

        it { expect{subject}.not_to change{Event.count} }

        it { is_expected.to be true }
      end

      context "that won't push" do
        before(:each) {
          expect(event.shadow_event)
            .to be_nil

          expect(GoogleCalendarApiHelper)
            .not_to receive(:push_event)
        }

        context "won't create anything when the event isn't being synced" do
          let(:event) { create :event }

          it { is_expected.to be true }
        end
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
