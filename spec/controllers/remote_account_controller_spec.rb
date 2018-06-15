# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoteAccountController, type: :controller do
  let(:user) { create :user }

  describe "#delete" do
    it "deletes an account" do
      account = create :remote_account, user: user
      account_id = account.id

      sign_in user

      delete :delete, id: account_id

      still_exists = RemoteAccount.find_by_id account_id
      expect(still_exists).to be_nil
      expect(response).to redirect_to(:dashboard)
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
