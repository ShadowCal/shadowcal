# frozen_string_literal: true

require "rails_helper"

describe "onboarding", type: :feature do
  before :each do
    @user = FactoryBot.create :user_with_google_account, num_google_accounts: 2
    login_as @user, scope: :user
  end

  it "shows loading screen until calendars arrive" do
    visit "/"
    page.should have_content("Loading your calendars")
  end

  it "shows form after calendars arrive" do
    @user.google_accounts.each do |acc|
      FactoryBot.create :calendar, google_account: acc
    end

    visit "/"
    page.should have_no_content("Loading your calendars")
    page.should have_css("form")

    page.should have_link("add another Google account")
  end

  it "creates first sync_pair by submitting form" do
    expected_from_calendar = FactoryBot.create  :calendar,
                                                name:           "Calendar1",
                                                google_account: @user.google_accounts.first

    expected_to_calendar = FactoryBot.create  :calendar,
                                              name:           "Calendar2",
                                              google_account: @user.google_accounts.last

    visit "/"
    select("Calendar1", from: "sync_pair_from_calendar_id")
    select("Calendar2", from: "sync_pair_to_calendar_id")

    expect(CalendarShadowHelper).to receive(:cast_from_to) do |from_calendar, to_calendar|
      expect(from_calendar).to eq expected_from_calendar
      expect(to_calendar).to eq expected_to_calendar
    end

    click_button("Block Time Privately")

    page.should have_css("table#existing_sync_pairs")
    find("table#existing_sync_pairs").should have_content("Calendar1")
    find("table#existing_sync_pairs").should have_content("Calendar2")

    # Once you have made first pair, you're onboarded and can see delete link
    page.should have_link("Delete Account")
  end
end
