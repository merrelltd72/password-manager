require 'sidekiq/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  #User routes
  post '/users' => 'users#create'

  #login route
  post '/sessions' => 'sessions#create'
  # check if user is logged in route
  get '/isLoggedIn' => 'sessions#isloggedin'
  #logout route
  delete '/sessions' => 'sessions#destroy'

  #Google login route
  get '/auth/google_oauth2/callback' => 'sessions#create'
  
  #Account routes
  get '/accounts' => 'accounts#index'
  post '/accounts' => 'accounts#create'
  get '/accounts/:id' => 'accounts#show'
  patch '/accounts/:id' => 'accounts#update'
  delete '/accounts/:id' => 'accounts#destroy'
  post '/account_upload' => 'accounts#upload_accounts'

  #Sidekiq web UI
  mount Sidekiq::Web => "/sidekiq"
end