Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get "/favicon.ico", to: proc { |_env| [200, {}, ["Lovely job"]] }
  get "/browse/:topic_slug", to: "browse#show_mainstream_topic"
  get "/browse/:topic_slug/:subtopic_slug", to: "browse#show_mainstream_subtopic"
  get "/topic/", to: "topic#show_topics"
  get "/topic/:topic_slug", to: "browse#show_specialist_topic"
  get "/topic/:topic_slug/:subtopic_slug", to: "topic#subtopic"
end
