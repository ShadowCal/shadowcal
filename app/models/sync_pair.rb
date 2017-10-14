class SyncPair < ActiveRecord::Base
  belongs_to :user
  belongs_to :from_google_account, class_name: "GoogleAccount"
  belongs_to :to_google_account, class_name: "GoogleAccount"

  def from_calendar_id
    if from_google_account_id.blank? or from_cal_id.blank?
      then nil
      else [from_google_account.email, from_cal_id].join(':')
    end
  end

  def from_calendar_id=(calendar_id)
    from_google_account_id, from_cal_id = if calendar_id.blank?
      then [nil, nil]
      else calendar_id.split(':')
    end
  end

  def to_calendar_id
    if to_google_account_id.blank? or to_cal_id.blank?
      then nil
      else [to_google_account.email, to_cal_id].join(':')
    end
  end

  def to_calendar_id=(calendar_id)
    to_google_account_id, to_cal_id = if calendar_id.blank?
      then [nil, nil]
      else calendar_id.split(':')
    end
  end
end
