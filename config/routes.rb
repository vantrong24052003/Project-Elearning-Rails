# frozen_string_literal: true

Rails.application.routes.draw do
  # Devise routes with Omniauth
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  # Define root path
  root to: 'home#index'

  # Define courses resource
  resources :courses, only: %i[index show]

  # Debugging route for OAuth
  get 'oauth_debug/check_callback', to: 'oauth_debug#check_callback'

  namespace :dashboard do
    resources :courses
  end

  namespace :manage do
    resources :courses
  end
end
