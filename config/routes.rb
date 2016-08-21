Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :articles do
    post :text_post, :on => :collection
  end

  root "articles#index"
end
