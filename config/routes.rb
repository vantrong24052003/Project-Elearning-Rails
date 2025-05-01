# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  namespace :dashboard do
    resources :courses, only: %i[index show new edit create update destroy] do
      resources :quizzes do
        resources :attempts, controller: 'quiz_attempts'
        resources :quiz_attempts
      end
      resources :payments
      resources :viewers
    end

    resources :uploads
    resources :quiz_attempts, only: %i[index show]
    resources :enrollments, only: %i[index]

    resources :profiles, only: %i[show update]

    resources :passwords, only: %i[edit update]
  end

  namespace :manage do
    resources :courses do
      member do
        post :publish
        post :draft
      end
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
  end

  root to: 'home#index'
end
