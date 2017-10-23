# frozen_string_literal: true

class StatusHash
  def [](key)
    raise "INVALID STATUS: '#{key}'" unless keys.include? key.to_s

    statuses[key.to_sym]
  end

  def as_json(options = {})
    statuses.as_json(options)
  end

  def keys
    statuses.keys.map(&:to_s)
  end
end

class GamePlayStatusHash < StatusHash
  private

  def statuses
    # Duplicated in app/assets/javascript/init.js.coffee
    {
      PENDING_INVITATIONS:           "PENDING_INVITATIONS",
      NOT_ENOUGH_PLAYERS:            "NOT_ENOUGH_PLAYERS",
      PENDING_GAME_START:            "PENDING_GAME_START",
      PENDING_ANSWERS:               "PENDING_ANSWERS",
      PENDING_REJECTION:             "PENDING_REJECTION",
      PENDING_QUESTION_CONFIRMATION: "PENDING_QUESTION_CONFIRMATION",
      ENDED:                         "ENDED"
    }
  end
end

class GameParticipationStatusHash < StatusHash
  private

  def statuses
    {
      ACCEPTED:   "ACCEPTED",
      IGNORED:    "IGNORED",
      ELIMINATED: "ELIMINATED",
      PENDING:    "PENDING"
    }
  end
end

class AnswerStatusHash < StatusHash
  private

  def statuses
    {
      ACCEPTED: "ACCEPTED",
      PENDING:  "PENDING",
      REJECTED: "REJECTED"
    }
  end
end

class GameTypeStatusHash < StatusHash
  private

  def statuses
    {
      DEFAULT: "MANUAL",
      MANUAL:  "MANUAL",
      FAST:    "FAST"
    }
  end
end
