Rails.application.routes.draw do
  api_version(:module => "V1", :path => {:value => "v1"}) do
    resources :crawls, path: 'crawl', param: :request_id, only:[:create, :show]
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
