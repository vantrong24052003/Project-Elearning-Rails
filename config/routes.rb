# frozen_string_literal: true
require 'sidekiq/web'

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

  namespace :manage do
    root to: 'courses#index'

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
    resources :quizzes do
      collection do
        get 'course_chapters/:course_id', to: 'quizzes#course_chapters', as: :course_chapters
        get 'chapter_lessons/:chapter_id', to: 'quizzes#chapter_lessons', as: :chapter_lessons
        get 'lesson_videos/:lesson_id', to: 'quizzes#lesson_videos', as: :lesson_videos
        get 'video_details/:video_id', to: 'quizzes#video_details', as: :video_details
      end

      resources :quiz_attempts, only: [:index]
    end
    resources :questions
    resources :quiz_attempts
    get 'quiz_dashboard', to: 'quiz_attempts#dashboard', as: :quiz_dashboard
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

  mount Sidekiq::Web => '/sidekiq'
end
