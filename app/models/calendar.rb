# frozen_string_literal: true

class Calendar < ActiveRecord::Base
  belongs_to :remote_account
  has_many :events, dependent: :destroy
  has_many :sync_pairs_from, dependent: :destroy, class_name: 'SyncPair', foreign_key: :from_calendar_id
  has_many :sync_pairs_to, dependent: :destroy, class_name: 'SyncPair', foreign_key: :to_calendar_id

  delegate :access_token, :email, :user, to: :remote_account

  def push_events(events)
    remote_account.push_events(external_id, events)
  end

  def push_event(event)
    remote_account.push_event(external_id, event)
  end

  def request_events
    remote_account.request_events(external_id)
  end

  def move_event(event_id, start_at, end_at)
    remote_account.move_event(external_id, event_id, start_at, end_at)
  end
end
