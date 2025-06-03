# frozen_string_literal: true

require 'sidekiq/web'
Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  namespace :manage do
    devise_scope :user do
      get 'login', to: 'sessions#new'
      post 'login', to: 'sessions#create'
      delete 'logout', to: 'sessions#destroy'
    end

    root to: 'overviews#index'

    resources :courses 
    resources :chapters
    resources :lessons
    resources :videos do
      resource :moderation, only: [:update]
      resource :video_analysis, only: [:create], path: 'analyze'
    end
    resources :quizzes do
      resources :quiz_attempts, only: [:index]
    end
    resources :questions
    resource :questions_template, only: [:show], defaults: { format: :xlsx }
    resource :questions_export, only: [:show], defaults: { format: :xlsx }
    resources :quiz_attempts
    resources :uploads do
      member do
        get :progress
        post :retry
      end
    end
    resources :enrollments
    resources :users
    resources :faqs
    resources :payments
    resources :reviews
    resources :overviews, only: [:index]
  end

  namespace :dashboard do
    root to: 'courses#index'

    resources :courses, only: %i[index show new edit create update destroy] do
      resources :quizzes do
        resources :attempts
        resources :quiz_attempts, only: %i[index show new create edit update destroy]
        resources :quiz_statuses, only: %i[index update] do
          collection do
            get 'get_ip'
          end
        end
      end
      resources :payments
      resources :viewers
    end

    resources :enrollments, only: %i[index]
    resources :profiles, only: %i[show update]
  end

  root to: 'home#index'

  mount Sidekiq::Web => '/sidekiq'
end
