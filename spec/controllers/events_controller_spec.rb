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



end
