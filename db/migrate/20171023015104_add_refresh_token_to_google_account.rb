class AddRefreshTokenToGoogleAccount < ActiveRecord::Migration
  def change
    add_column :google_accounts, :refresh_token, :string
    remove_column :google_accounts, :token_expires, :integer
    add_column :google_accounts, :token_expires_at, :datetime
  end
end
