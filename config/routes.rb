require 'resque/server'

Reckoning::Application.routes.draw do
  mount RailsAssetLocalization::Engine => "/locales"

  devise_for :users, skip: [:sessions], controllers: { registrations: "registrations" }

  namespace :backend do
    resources :users, except: [:show]

    resources :settings, except: [:index, :show]

    authenticate :user, lambda {|u| u.admin? } do
      mount Resque::Server.new, :at => "/workers"
    end

    root to: 'base#dashboard'
  end

  namespace :api do
    resources :tasks
    resources :timers
  end

  as :user do
    get 'signup' => 'registrations#new', as: :new_registration
    get 'signin' => 'sessions#new', as: :new_user_session
    post 'signin' => 'sessions#create', as: :user_session
    delete 'signout' => 'sessions#destroy', as: :destroy_user_session
  end

  resource :password, only: [:edit, :update]

  resources :invoices, param: :ref do
    member do
      put :generate_positions
      put :regenerate_pdf
      put :charge
      put :pay
      get :check_pdf
      put :archive
    end
  end

  get 'invoices/:ref/pdf/:pdf' => 'invoices#pdf', as: :invoice_pdf
  get 'invoices/:ref/png/:png' => 'invoices#png', as: :invoice_png
  get 'timesheets/:ref/pdf/:pdf' => 'invoices#timesheet', as: :timesheet_pdf
  get 'timesheets/:ref/png/:png' => 'invoices#timesheet_png', as: :timesheet_png

  resources :positions, only: [:new, :destroy]

  resources :customers, except: [:show]
  resources :projects, except: [:show] do
    resources :tasks, only: [:index, :create] do
      get ':date/date' => 'tasks#index_for_date', as: :date, on: :collection
    end
  end

  resources :timers, only: [:index] do
    collection do
      get :day
      get :new_import
      post :csv_import
    end
  end

  resources :weeks, only: [:create, :update] do
    collection do
      post :add_task
    end
    member do
      put 'remove_task/:task_id' => 'weeks#remove_task', as: :remove_task
    end
  end

  get '404' => 'errors#not_found'
  get '422' => 'errors#server_error'
  get '500' => 'errors#server_error'

  root to: 'base#index'
end
