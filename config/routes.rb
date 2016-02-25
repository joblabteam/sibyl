Sibyl::Engine.routes.draw do
  post "webhooks/:sibyl_event", to: "webhooks#webhook"

  resources :dashboard, only: [:index]

  resources :events do
    get :kinds, on: :collection
  end
end
