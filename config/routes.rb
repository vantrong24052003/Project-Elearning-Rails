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
        get :course_viewer
        get :payment
        post :demo_success
      end

      resources :quizzes
    end
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
