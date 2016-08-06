class SyncPair < ActiveRecord::Base
  belongs_to :user
  belongs_to :from_google_account, class_name: "GoogleAccount"
  belongs_to :to_google_account, class_name: "GoogleAccount"
end
