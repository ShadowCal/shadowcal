
class StubCalendar
  attr_accessor(:id, :summary)

  def initialize(id, summary)
    @id = id
    @summary = summary
  end
end

class StubAccount < GoogleAccount
  attr_accessor(:email, :calendars)

  def initialize(email, calendars=[])
    @email = email
    @calendars = calendars
  end
end
