ShadowCal::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "omniauth_callbacks" }

  # user_root overrides device's after-login route
  match 'dashboard' => 'user#dashboard', :as => 'user_root', via: [:get, :post]

  match 'user/:user_id/sync_pair' => 'sync_pairs#create', via: [:post], as: :user_sync_pairs

  root to: 'user#dashboard', as: :dashboard
end
