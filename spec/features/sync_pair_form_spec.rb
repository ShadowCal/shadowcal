# frozen_string_literal: true

require "rails_helper"

describe "sync_pair_form", type: :feature do
  before :each do
    @pair = FactoryBot.create :sync_pair
    @user = @pair.user
    login_as @user, scope: :user

    visit new_sync_pair_path
  end

  it "groups calendars by account" do
    expect(page).to have_select("From", with_options: @user.calendars.map(&:name))
    expect(page).to have_select("Onto", with_options: @user.calendars.map(&:name))

    @user.remote_accounts.each do |acc|
      expect(page).to have_css("optgroup[label=\"#{acc.email}\"]")
      acc.calendars.each do |cal|
        expect(page).to have_css("optgroup[label=\"#{acc.email}\"] option[value=\"#{cal.id}\"]", text: cal.name)
      end
    end
  end
end
