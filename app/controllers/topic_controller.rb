require 'httparty'

class TopicController < ApplicationController

  def show
    browse_slug = params[:slug]

    url = "https://www.gov.uk/api/content/topic/#{browse_slug}"
    content_item = http_get(url).parsed_response

    subtopics = content_item["links"]["children"].sort_by { |k| k["title"] }


    payload = {
      title: content_item["title"],
      description: content_item["description"],
      subtopics: subtopics.map {
        |subtopic| {
          title: subtopic["title"],
          link: subtopic["base_path"]
        }
      }
    }

    render json: payload
  end


  def show_topics
    browse_slug = params[:slug]
    url = "https://www.gov.uk/api/content/topic"

    content_item = http_get(url).parsed_response

    subtopics = content_item["links"]["children"].sort_by { |k| k["title"] }


    payload = {
      title: content_item["title"],
      description: content_item["description"],
      subtopics: subtopics.map {
        |subtopic| {
          title: subtopic["title"],
          link: subtopic["base_path"]
        }
      }
    }

    render json: payload
  end

  # def subtopic
  #   payload = {"a": 2}
  #   render json: payload
  # end
end


private

  def http_get(url)
    HTTParty.get(url)
  end
