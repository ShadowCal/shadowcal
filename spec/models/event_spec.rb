# frozen_string_literal: true

require "rails_helper"

describe "Event", type: :model do
  let(:event) { FactoryBot.create :event }
  let(:new_event) { FactoryBot.build :event }

  describe "#moved?" do
    it "returns true if start date was changed" do
      event.start_at = event.start_at + 1.minute
      expect(event.moved?).to be_truthy
    end

    it "returns true if end date was changed" do
      event.end_at = event.end_at + 1.minute
      expect(event.moved?).to be_truthy
    end

    it "returns false if neither has changed" do
      event.name = "Not #{event.name}"
      expect(event.moved?).to be_falsy
    end

    it "returns false if the object is new" do
      new_event.start_at = new_event.start_at + 1.minute
      expect(new_event.moved?).to be_falsy
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
        expect{ subject }.to raise_error
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
        expect{ subject }.to raise_error
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
