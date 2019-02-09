# frozen_string_literal: true

class CreateCalendars < ActiveRecord::Migration
  def change
    create_table :calendars do |t|
      t.references :google_account, index: true
      t.string :external_id
      t.string :name

      t.timestamps
    end
  end
end
