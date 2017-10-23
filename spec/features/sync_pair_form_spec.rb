require 'rails_helper'

describe "sync_pair_form", :type => :feature do
  before :each do
    @pair = FactoryGirl.create :sync_pair
    @user = @pair.user
    login_as @user, scope: :user

    visit new_sync_pair_path
  end

  it "groups calendars by account" do
    page.should have_select('From', with_options: @user.calendars.map(&:name))
    page.should have_select('Onto', with_options: @user.calendars.map(&:name))

    @user.google_accounts.each do |acc|
      page.should have_css("optgroup[label=\"#{acc.email}\"]")
      acc.calendars.each do |cal|
        page.should have_css("optgroup[label=\"#{acc.email}\"] option[value=\"#{cal.id}\"]", text: cal.name)
      end
    end
  end

  it "allows user to add new google account" do
    page.should have_link('add another Google account')
  end
end
