class CreateSyncPairs < ActiveRecord::Migration
  def change
    create_table :sync_pairs do |t|
      t.integer :user_id
      t.string :from_cal_id
      t.integer :from_google_account_id
      t.string :to_cal_id
      t.integer :to_google_account_id

      t.timestamps
    end
    add_index :sync_pairs, :user_id
    add_index :sync_pairs, :from_google_account_id
    add_index :sync_pairs, :to_google_account_id
  end
end
