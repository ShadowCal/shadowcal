class UserController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @sync_pairs = current_user.sync_pairs
    @google_accounts = current_user.google_accounts
    @calendars_by_google_account = @google_accounts.group_by(&:email).map{ |k,a| [k,a.map(&:calendars).flatten.map{|c| [c.summary, [k,c.id].join(":")]}] }

    @sync_pair = current_user.sync_pairs.build
  end


end
