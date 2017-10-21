class UserController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @google_accounts = current_user.google_accounts
    @calendars_by_google_account = CalendarAccountHelper.from_accounts_by_key(@google_accounts)
    @has_calendars = @google_accounts.all? {|acc| acc.calendars.any? }

    @existing_sync_pairs = current_user.sync_pairs
  end


end
