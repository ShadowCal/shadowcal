# frozen_string_literal: true

require "rails_helper"

describe "onboarding", type: :feature do
  before :each do
    @user = FactoryBot.create :user_with_google_account, num_google_accounts: 2
    login_as @user, scope: :user
  end

  it "shows loading screen until calendars arrive" do
    visit "/"
    expect(page).to have_content("Loading your calendars")
  end

  it "shows form after calendars arrive" do
    @user.remote_accounts.each do |acc|
      FactoryBot.create :calendar, remote_account: acc
    end

    visit "/"
    expect(page).to have_no_content("Loading your calendars")
    expect(page).to have_css("form")

    expect(page).to have_link("add another Google account")
  end

  it "creates first sync_pair by submitting form" do
    expected_from_calendar = FactoryBot.create  :calendar,
                                                name:           "Calendar1",
                                                remote_account: @user.remote_accounts.first

    expected_to_calendar = FactoryBot.create  :calendar,
                                              name:           "Calendar2",
                                              remote_account: @user.remote_accounts.last

    visit "/"
    select("Calendar1", from: "sync_pair_from_calendar_id")
    select("Calendar2", from: "sync_pair_to_calendar_id")

    expect(CalendarShadowHelper).to receive(:cast_from_to) do |from_calendar, to_calendar|
      expect(from_calendar).to eq expected_from_calendar
      expect(to_calendar).to eq expected_to_calendar
    end

    click_button("Block Time Privately")

    expect(page).to have_css("table#existing_sync_pairs")
    expect(find("table#existing_sync_pairs")).to have_content("Calendar1")
    expect(find("table#existing_sync_pairs")).to have_content("Calendar2")

    # Once you have made first pair, you're onboarded and can see delete link
    expect(page).to have_link("Delete Account")
  end
end
