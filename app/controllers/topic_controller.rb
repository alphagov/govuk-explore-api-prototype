require 'httparty'
require 'json'

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

    # hydra = Typhoeus::Hydra.new

    # requests = subtopics.map {
    #   | subtopic |
    #   request = Typhoeus::Request.new("https://www.gov.uk/#{subtopic["api_path"]}")
    #   hydra.queue request
    #   request
    # }

    # hydra.run

    payload = {
      title: content_item["title"],
      description: content_item["description"],
      # subtopics: requests.map {
      #   | request |
      #   subtopic_obj = JSON.parse(request.response.body)
      #   {
      #     title: subtopic_obj["title"],
      #     link: subtopic_obj["base_path"],
      #     description: subtopic_obj["description"]
      #   }
      # }
      subtopics: subtopics.map {
        | subtopic | {
          title: subtopic["title"],
          link: subtopic["base_path"]
        }
      }
    }

    render json: payload

  # def subtopic
  #   payload = {"a": 2}
  #   render json: payload
  # end
  end


private

  def get_subtopic_info(api_url)
    content_item = http_get(api_url).parsed_response
    {
      title: content_item["title"],
      description: content_item["description"],
      link: content_item["base_path"]
    }
  end

  def http_get(url)
    HTTParty.get(url)
  end

end
