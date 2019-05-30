# frozen_string_literal: true

ShadowCal::Application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }

  match "sync_pair" => "sync_pairs#create", :via => [:post], :as => :sync_pairs
  match "sync_pair/:id/now" => "sync_pairs#sync_now", :via => [:get], :as => :sync_pair_now
  match "sync_pair/new" => "sync_pairs#new", :via => [:get], :as => :new_sync_pair
  match "remote_account/:id" => "remote_account#delete", :via => [:delete], :as => :delete_remote_account
  match "user" => "user#delete", :via => [:delete], :as => :user_delete
  match "schedule/:user_id" => "events#new", via: [:get], as: :schedule_event

  root to: "user#dashboard", as: :dashboard
end
