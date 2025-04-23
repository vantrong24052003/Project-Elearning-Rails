# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  namespace :dashboard do
    resources :courses do
      member do
        patch :publish
        patch :unpublish
      end
    end
  end

  namespace :manage do
    resources :courses do
      member do
        post :publish
        post :draft
      end
    end
  end

  root to: 'home#index'
end
