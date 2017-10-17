module CalendarAccountHelper
  def from_accounts_by_key(accounts)
    accounts.map{ |a| calendars_by_google_account(a) }
  end

  private
  def calendar_as_select_option(summary, calendar_key)
    [summary, calendar_key]
  end

  def account_and_calendar_composite_key(account_key, calendar_key)
    [account_key, calendar_key].join(':')
  end

  def calendar_options(account_key, calendars)
    calendars.map do |cal|
      calendar_as_select_option(
        cal.summary,
        account_and_calendar_composite_key(account_key, cal.id)
      )
    end
  end

  def calendar_options_by_account_key(account_key, calendars)
    [account_key, calendar_options(account_key, calendars)]
  end

  def calendars_by_google_account(account)
    calendar_options_by_account_key(account.email, account.calendars)
  end

  extend self
end
