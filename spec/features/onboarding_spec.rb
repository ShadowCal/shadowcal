describe "onboarding", :type => :feature do
  before :each do
    @user = FactoryGirl.create :user_with_google_account
    login_as @user, scope: :user
  end

  it "shows loading screen until calendars arrive" do
    visit '/'
    page.should have_content('Loading your calendars')
  end

  it "shows form after calendars arrive" do
    @user.google_accounts.first.calendars.build.save

    visit '/'
    page.should have_no_content('Loading your calendars')
    page.should have_css('form')

    page.should have_link('add another Google account')
  end

  it "creates first sync_pair by submitting form" do
    @user.google_accounts.first.calendars.build(name: "Calendar1").save!
    @user.google_accounts.first.calendars.build(name: "Calendar2").save!

    visit '/'
    select('Calendar1', :from => 'sync_pair_from_calendar_id')
    select('Calendar2', :from => 'sync_pair_to_calendar_id')
    click_button('Block Time Privately')

    page.should have_css('table#existing_sync_pairs')
    find('table#existing_sync_pairs').should have_content('Calendar1')
    find('table#existing_sync_pairs').should have_content('Calendar2')
    find('table#existing_sync_pairs').should have_content('never')


    # Once you have made first pair, you're onboarded and can see delete link
    page.should have_link('Delete Account')
  end
end
