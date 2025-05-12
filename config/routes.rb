# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  namespace :dashboard do
    root to: 'courses#index'

    resources :courses, only: %i[index show new edit create update destroy] do
      get 'quiz_attempts/in_progress', to: 'quiz_attempts#in_progress'
      resources :quizzes do
        resources :attempts
        resources :quiz_attempts do
          member do
            post :log_action
            post :update_behavior_counts
          end
        end
      end
      resources :payments
      resources :viewers
    end

    resources :enrollments, only: %i[index]
    resources :profiles, only: %i[show update]
    resources :passwords, only: %i[edit update]
  end

  namespace :manage do
    root to: 'overviews#index'

    resources :overviews, only: %i[index]

    resources :courses do
      member do
        post :publish
        post :draft
      end
    end

    resources :chapters
    resources :lessons
    resources :videos do
      resource :moderation, only: [:update]
    end
    resources :quizzes
    resources :questions
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
  end

  root to: 'home#index'
end
