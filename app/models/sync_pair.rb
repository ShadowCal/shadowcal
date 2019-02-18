# frozen_string_literal: true

class SyncPair < ActiveRecord::Base
  belongs_to :user

  belongs_to :to_calendar, class_name: "Calendar", foreign_key: "to_calendar_id"
  belongs_to :from_calendar, class_name: "Calendar", foreign_key: "from_calendar_id"

  validates :to_calendar, :from_calendar, presence: true
  validates_uniqueness_of :from_calendar

  validate :ownership
  validate :one_way_syncing
  validate :no_syncing_to_from_same

  after_create :perform_sync, unless: :skip_callbacks

  def perform_sync
    CalendarShadowHelper.cast_from_to(from_calendar, to_calendar)
    update_attributes! last_synced_at: Time.current
  end

  private

  def ownership
    return if user_id.blank?

    errors[:from_calendar_id] << 'must be a calendar you own' unless user_id == from_calendar.user.id || from_calendar_id.nil?
    errors[:to_calendar_id] << 'must be a calendar you own' unless user_id == to_calendar.user.id || to_calendar_id.nil?
  end

  def one_way_syncing
    errors[:from_calendar_id] << 'cannot sync from a calendar already being synced to' if from_calendar_id && user.sync_pairs.where('to_calendar_id = ? AND id <> ?', from_calendar_id, id).count.positive?
    errors[:to_calendar_id] << 'cannot sync to a calendar already being synced from' if to_calendar_id && user.sync_pairs.where('from_calendar_id = ? AND id <> ?', to_calendar_id, id).count.positive?
  end

  def no_syncing_to_from_same
    errors[:base] << 'cannot sync calendar to itself' if from_calendar_id == to_calendar_id && !from_calendar_id.blank?
  end
end
