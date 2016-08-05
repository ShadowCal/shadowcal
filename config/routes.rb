ShadowCal::Application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  devise_for :users, :controllers => { :omniauth_callbacks => "omniauth_callbacks" }

  ActiveAdmin.routes(self)

  # user_root overrides device's after-login route
  match 'dashboard' => 'user#dashboard', :as => 'user_root', via: [:get, :post]

  match 'nilas/connect'   => 'nilas#connect',   as: 'nilas_connect',  via: [:get, :post]
  match 'nilas/callback'  => 'nilas#callback',  as: 'nilas_callback', via: [:get, :post]

  root to: 'user#dashboard'
end
