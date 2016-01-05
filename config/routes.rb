Sibyl::Engine.routes.draw do
  post "webhooks/:sibyl_event", to: "webhooks#webhook"

  resources :dashboard, only: [:index]

  resources :events
end
