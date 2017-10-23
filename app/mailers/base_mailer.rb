# frozen_string_literal: true

class BaseMailer
  class << self
    include Rails.application.routes.url_helpers
  end

  class << self
    protected

    def trigger_message(user, mail_name, properties = {})
      Analytics.track_event user, "trigger_message_#{mail_name}", properties
    end
  end
end
