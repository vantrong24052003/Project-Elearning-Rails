# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    unlocks: 'users/unlocks'
  }

  root to: 'home#index'

  resources :courses, only: %i[index show] do
    collection do
      get :search
      get :categories
    end
    member do
      post :enroll
    end
  end

  get 'about', to: 'pages#about'
  get 'contact', to: 'pages#contact'
  get 'terms', to: 'pages#terms'

  get 'oauth_debug/check_callback', to: 'oauth_debug#check_callback'

  namespace :dashboard do
    root to: 'dashboard#index'

    resource :profile, only: %i[show edit update]

    resources :courses do
      resources :lessons
      resources :chapters
      resources :students, only: %i[index show]
      resources :reviews, only: %i[index show]

      member do
        patch :publish
        patch :unpublish
      end
    end

    resources :enrollments, only: %i[index show]
    resources :certificates, only: %i[index show]

    namespace :instructor do
      resources :courses
      resources :analytics, only: [:index]
    end

    namespace :admin do
      resources :users
      resources :categories
      resources :settings

      resources :instructor_requests, only: %i[index show] do
        member do
          post :approve
          post :reject
        end
      end
    end
  end

  get 'dashboard', to: 'dashboard#index'

  namespace :manage do
    resources :courses
  end
end
