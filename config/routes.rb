# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  resources :courses, only: %i[index show] do
    resources :chapters, only: %i[index show] do
      resources :lessons, only: [:show]
    end
    resources :quizzes, only: [:show] do
      member do
        post :attempt
      end
    end
    resources :enrollments, only: [:create]
  end

  resources :quiz_attempts, only: [:show]
  resources :enrollments, only: %i[index show]

  namespace :dashboard do
    resources :courses do
      member do
        patch :publish
        patch :unpublish
      end
      resources :chapters do
        resources :lessons do
          resources :videos
        end
      end
      resources :quizzes do
        resources :questions
      end
      resources :enrollments, only: %i[index show update]
    end
    resources :uploads
    resources :quiz_attempts, only: %i[index show]
    resources :enrollments, only: [:index]

    root to: 'courses#index'
  end

  namespace :manage do
    resources :courses do
      member do
        post :publish
        post :draft
      end
      resources :enrollments, only: [:index]
    end
    resources :chapters
    resources :lessons
    resources :videos
    resources :quizzes
    resources :questions
    resources :quiz_attempts
    resources :uploads
    resources :enrollments
    resources :users
    resources :faqs
    resources :payments
    resources :reviews

    root to: 'dashboard#index'
  end

  root to: 'home#index'
end
