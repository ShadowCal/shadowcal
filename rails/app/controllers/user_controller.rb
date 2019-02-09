# frozen_string_literal: true

class UserController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @remote_accounts = current_user.remote_accounts
    @calendars_by_remote_account = CalendarAccountHelper.from_accounts_by_key(@remote_accounts)

    @existing_sync_pairs = current_user.sync_pairs
  end

  def delete
    current_user.destroy
    redirect_to :dashboard, notice: "Your account has been removed"
  end
end
