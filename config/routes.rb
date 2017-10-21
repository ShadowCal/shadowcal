ShadowCal::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "omniauth_callbacks" }

  # user_root overrides device's after-login route
  match 'dashboard' => 'user#dashboard', :as => 'user_root', via: [:get, :post]

  match 'sync_pair' => 'sync_pairs#create', via: [:post], as: :sync_pairs
  match 'sync_pair/:id/now' => 'sync_pairs#sync_now', via: [:get], as: :sync_pair_now
  match 'sync_pair/new' => 'sync_pairs#new', via: [:get], as: :new_sync_pair

  root to: 'user#dashboard', as: :dashboard
end
