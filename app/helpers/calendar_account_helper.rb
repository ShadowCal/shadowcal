module CalendarAccountHelper
  def from_accounts_by_key(accounts)
    accounts.map{ |a| calendars_by_google_account(a) }
  end

  private
  def calendar_options(calendars)
    calendars.map do |cal|
      [
        cal.name,
        cal.id
      ]
    end
  end

  def calendar_options_by_account_key(account_key, calendars)
    [account_key, calendar_options(calendars)]
  end

  def calendars_by_google_account(account)
    calendar_options_by_account_key(account.email, account.calendars)
  end

  extend self
end
