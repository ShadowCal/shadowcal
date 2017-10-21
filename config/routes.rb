ShadowCal::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "omniauth_callbacks" }

  match 'sync_pair' => 'sync_pairs#create', via: [:post], as: :sync_pairs
  match 'sync_pair/:id/now' => 'sync_pairs#sync_now', via: [:get], as: :sync_pair_now
  match 'sync_pair/new' => 'sync_pairs#new', via: [:get], as: :new_sync_pair

  match 'user' => 'user#delete', via: [:delete], as: :user_delete

  root to: 'user#dashboard', as: :dashboard
end
