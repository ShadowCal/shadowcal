require 'rails_helper'

describe "User", :type => :model do

  let(:user) {FactoryGirl.create :user}

  describe '#add_or_update_google_account' do
    before :each do
      expect(user.google_accounts.count).to eq 0 #sanity
      user.add_or_update_google_account(Faker::Omniauth.unique.google.to_ostruct)
    end

    it 'adds a new google account' do
      expect(user.google_accounts.count).to eq 1
    end

    it 'adds a second google account' do
      user.add_or_update_google_account(Faker::Omniauth.unique.google.to_ostruct)
      expect(user.google_accounts.count).to eq 2
    end

    it 'records refresh_token' do
      expect(user.google_accounts.first.refresh_token).to_not be_nil
    end
  end
end
