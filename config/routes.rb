Sibyl::Engine.routes.draw do
  resources :dashboard, only: [:index]

  resources :events
end
