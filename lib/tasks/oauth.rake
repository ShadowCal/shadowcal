namespace :oauth do
  def log(msg)
    Rails.logger.info ['[oauth#refresh_tokens]', msg].join(' ')
  end

  desc "Refresh all the tokens of all the accounts which are stale"
  task refresh_tokens: :environment do
    log "There are #{GoogleAccount.count} total accounts. #{GoogleAccount.to_be_refreshed.count} need to be refreshed."
    GoogleAccount.to_be_refreshed.each do |account|
      # We don't need to do anything with the instance, because each
      # access_token is refreshed automatically when the instance is
      # initialized.
      log "Refreshed token for #{account.email}. Good until #{account.token_expires_at}"
    end
  end

end
