# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoteAccountController, type: :controller do
  let(:user) { create :user }

  describe "#delete" do
    it "deletes an account" do
      expect {
        pair = create :sync_pair, user: user
        account = pair.from_calendar.remote_account
        account_id = account.id

        sign_in user

        delete :delete, id: account_id
        expect(response).to redirect_to(:dashboard)

        still_exists = RemoteAccount.find_by_id account_id
        expect(still_exists).to be_nil
      }.to avoid_changing{ Event.count }
        .and avoid_changing{ SyncPair.count }
        .and(change{ Calendar.count }.by(1))
        .and(change{ RemoteAccount.count }.by(1))
        .and(change{ User.count }.by(1))
    end

    it "only deletes an account owned by the user" do
      account = create :remote_account
      account_id = account.id

      sign_in user

      delete :delete, id: account_id

      still_exists = RemoteAccount.find_by_id account_id
      expect(still_exists).to be_truthy
    end
  end
end
