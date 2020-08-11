Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get "/favicon.ico", to: proc { |_env| [200, {}, ["Lovely job"]] }
  get "/browse/:slug", to: "browse#show"
  get "/browse/:slug/:subtopic_slug", to: "browse#subtopic"
end
