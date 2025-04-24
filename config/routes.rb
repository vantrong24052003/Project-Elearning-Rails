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

  # Phần quản lý cho admin
  namespace :manage do
    root to: 'dashboard#index'

    # Thêm resources :users
    resources :users
    resources :enrollments
    resources :lessons
    resources :videos
    resources :reviews
    resources :payments
    resources :faqs

    # Chỉ định nghĩa route cho courses
    resources :courses do
      collection do
        post :bulk_publish
        post :bulk_draft
        post :bulk_delete
      end

      member do
        put :publish
        put :draft
      end
    end
  end

  root to: 'home#index'
end
