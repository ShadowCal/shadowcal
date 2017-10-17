class UserController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @existing_sync_pairs = current_user.sync_pairs
    @google_accounts = current_user.google_accounts
    @calendars_by_google_account = CalendarAccountHelper.from_accounts_by_key(@google_accounts)

    @sync_pair = current_user.sync_pairs.build
  end


end
