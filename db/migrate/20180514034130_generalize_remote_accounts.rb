class GeneralizeRemoteAccounts < ActiveRecord::Migration
  def change
    # Renames the table and index on user_id
    rename_table :google_accounts, :remote_accounts

    # Add the "type" column
    add_column :remote_accounts, :type, :string

    # Renames the one foreign key, and it's index
    rename_column :calendars, :google_account_id, :remote_account_id
  end
end
