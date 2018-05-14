# frozen_string_literal: true

require "rails_helper"

describe "dashboard", type: :feature do
  before :each do
    @pair = FactoryBot.create :sync_pair, last_synced_at: 3.hours.ago
    login_as @pair.user, scope: :user
    visit "/"
  end

  it "shows when a pair is last synced" do
    expect(find("#existing_sync_pairs")).to have_content("3 hours ago")

    # And can manually sync a pair
    expect(CalendarShadowHelper).to receive(:cast_from_to) do |from_calendar, to_calendar|
      expect(from_calendar).to eq @pair.from_calendar
      expect(to_calendar).to eq @pair.to_calendar
    end
    click_link("Sync Now")

    # Which updates the last_synced_at
    expect(find("#existing_sync_pairs")).to have_content("less than a minute ago")
    @pair.reload
    expect(@pair.last_synced_at).to be_within(5.seconds).of(Time.current)
  end

  it "allows user to add new shadow" do
    page.click_button("Add")
    expect(find("#existing_sync_pairs").find_link("New Shadow")[:href]).to eq new_sync_pair_path
  end

  it "allows user to add new google account" do
    page.click_button("Add")
    expect(page).to have_link("A Google Account")
  end
end
