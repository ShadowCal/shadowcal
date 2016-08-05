class CreateGoogleAccounts < ActiveRecord::Migration
  def change
    create_table :google_accounts do |t|
      t.references :user
      t.string :access_token
      t.string :token_secret
      t.integer :token_expires
      t.string :email

      t.timestamps
    end
    add_index :google_accounts, [:user_id]
  end
end
