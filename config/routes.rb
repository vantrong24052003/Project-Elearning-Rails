# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  resources :quiz_attempts, only: %i[show]
  resources :enrollments, only: %i[index show]

  namespace :dashboard do
    resources :courses do
      member do
        patch :publish
        patch :unpublish
        get :course_viewer
        get :payment
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

    resources :carts, only: %i[create destroy]
    resources :enrollments, only: %i[create]
    resources :uploads
    resources :quiz_attempts, only: %i[index show]
    resources :enrollments, only: %i[index]

    root to: 'courses#index'
  end

  namespace :manage do
    resources :courses do
      member do
        post :publish
        post :draft
      end
      resources :enrollments, only: %i[index]
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
