# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  let(:calendar) { create :calendar }
  let(:user) { calendar.user }

  before(:each) {
    user.update_attributes scheduling_calendar_id: calendar.id
  }

  it "sets the user" do
    get :new, user_id: user.id
    expect(assigns(:user)).to eq(user)
  end

  it "sets the timezone from the user's scheduling calendar" do
    get :new, user_id: user.id
    expect(assigns(:time_zone)).to eq(calendar.time_zone)
  end

  describe "@busy_times" do
    let!(:event) { create :event, calendar: calendar }
    let!(:blocking_event) { create :event, :is_blocking, calendar: calendar }

    it "includes blocking event" do
      get :new, user_id: user.id
      expect(assigns(:busy_times)).to include(blocking_event)
    end

    it "omits non-blocking event" do
      get :new, user_id: user.id
      expect(assigns(:busy_times)).not_to include(event)
    end
  end
end
