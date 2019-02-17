# frozen_string_literal: true

class SyncPair < ActiveRecord::Base
  belongs_to :user

  belongs_to :to_calendar, class_name: "Calendar", foreign_key: "to_calendar_id"
  belongs_to :from_calendar, class_name: "Calendar", foreign_key: "from_calendar_id"

  validates :to_calendar, :from_calendar, presence: true
  validates_uniqueness_of :from_calendar

  validate :ownership
  validate :one_way_syncing

  after_create :perform_sync, unless: :skip_callbacks

  def perform_sync
    CalendarShadowHelper.cast_from_to(from_calendar, to_calendar)
    update_attributes! last_synced_at: Time.current
  end

  private
    def ownership
      return if user_id.blank?
      unless user_id == from_calendar.user.id or from_calendar_id.nil?
        errors[:from_calendar_id] << 'must be a calendar you own'
      end
      unless user_id == to_calendar.user.id or to_calendar_id.nil?
        errors[:to_calendar_id] << 'must be a calendar you own'
      end
    end

    def one_way_syncing
      if from_calendar_id and user.sync_pairs.where('to_calendar_id = ?', from_calendar_id).count > 0
        errors[:from_calendar_id] << 'cannot sync from a calendar already being synced to'
      end

      if to_calendar_id and user.sync_pairs.where('from_calendar_id = ?', to_calendar_id).count > 0
        errors[:to_calendar_id] << 'cannot sync to a calendar already being synced from'
      end
    end
end
