class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.references :calendar, index: true
      t.string :name
      t.datetime :start_at
      t.datetime :end_at
      t.string :external_id
      t.references :source_event, index: true

      t.timestamps null: false
    end

    add_foreign_key :events, :calendars
    add_foreign_key :events, :events, column: :source_event_id
  end
end
