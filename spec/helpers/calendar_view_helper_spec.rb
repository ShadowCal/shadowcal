# frozen_string_literal: true

require "rails_helper"

describe CalendarViewHelper do
  describe "#timeslots" do
    def test_timeslots(block)

    end

    it "calls the block once per hour across a whole day" do
      opts = {
        start_at: Time.zone.now.beginning_of_day,
        end_at: Time.zone.now.end_of_day,
        interval: 1.hour
      }

      expect{ |probe|
        CalendarViewHelper.timeslots(opts, &probe)
      }.to yield_control.exactly(24).times
    end

    it "calls the block once every 15 minutes across a work day" do
      opts = {
        start_at: Time.zone.now.beginning_of_day + 9.hours,
        end_at: Time.zone.now.beginning_of_day + 20.hours,
        interval: 15.minutes
      }

      expect{ |probe|
        CalendarViewHelper.timeslots(opts, &probe)
      }.to yield_control.exactly(44).times
    end

    it "calls the block with each time" do
      beginning_of_day = Time.zone.now.beginning_of_day

      opts = {
        start_at: beginning_of_day,
        end_at: beginning_of_day + 3.hours,
        interval: 1.hours
      }

      expect{ |probe|
        CalendarViewHelper.timeslots(opts, &probe)
      }.to yield_successive_args(
        beginning_of_day,
        beginning_of_day + 1.hours,
        beginning_of_day + 2.hours
      )
    end
  end
end
