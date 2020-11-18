require 'httparty'
require 'json'

class TopicController < ApplicationController


  def show
    topic_slug = params[:slug]

    url = "https://www.gov.uk/api/content/topic/#{topic_slug}"

    content_item = http_get(url).parsed_response

    subtopics = content_item["links"]["children"]

    payload = {
      title: content_item["title"],
      description: content_item["description"],
      taxon_search_filter: (Taxonomies.taxon_filter_lookup("/browse/#{topic_slug}") || ""),
      latest_news: latest_news_content.map{ |news_result|
        {
          title: news_result["title"],
          description: news_result["description"],
          url: news_result["_id"],
          topic: news_result["content_purpose_supergroup"],
          subtopic: news_result["content_purpose_subgroup"],
          image_url: news_result["image_url"] || "https://assets.publishing.service.gov.uk/media/5e59279b86650c53b2cefbfe/placeholder.jpg",
          public_timestamp: news_result["public_timestamp"],
        }
      },
      organisations: topic_organisations,
      featured: most_popular_content(subtopics),
      subtopics: subtopics.map{ |subtopic|
        subtopic_details = http_get(subtopic["api_url"]).parsed_response

        content =  accordion_content(subtopic_details)

        {
          title: subtopic["title"],
          link: subtopic["base_path"],
          subtopic_sections: {
            items: content
          }
        }
      }.compact
    }

    render json: payload
  end



  # def show
  #   topic_slug = params[:slug]

  #   url = "https://www.gov.uk/api/content/topic/#{topic_slug}"
  #   content_item = http_get(url).parsed_response

  #   payload = {
  #     title: content_item["title"],
  #     description: content_item["description"],
  #     taxon_search_filter: (Taxonomies.taxon_filter_lookup("/topic/#{topic_slug}") || ""),
  #     subtopics: content_item["links"]["children"].map{ |sub|
  #       {
  #         title: sub["title"],
  #         link: sub["base_path"]
  #       }
  #     }
  #   }

  #   render json: payload
  # end


  def subtopic
    topic_slug = params[:slug]
    subtopic_slug = params[:subtopic_slug]

    url = "https://www.gov.uk/api/content/topic/#{topic_slug}/#{subtopic_slug}"
    content_item = http_get(url).parsed_response

    payload = {
      title: content_item["title"],
      description: content_item["description"],
      taxon_search_filter: (Taxonomies.taxon_filter_lookup("/topic/#{topic_slug}/#{subtopic_slug}") || ""),
      subtopics: content_item["links"]["children"].map{ |sub|
        {
          title: sub["title"],
          link: sub["base_path"]
        }
      },
      parent:
        {
          link: content_item["links"]["parent"][0]["base_path"],
          title: content_item["links"]["parent"][0]["title"]
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

  def topic_filter(topic_slug)
    taxon_id = Taxonomies.mainstream_content_id(topic_slug)

    if taxon_id.present?
      { filter_part_of_taxonomy_tree: taxon_id }
    else
     {}
    end
  end

  def latest_news_content
    topic_query["results"]
  end



  def topic_query
    @topic_query ||= begin
      topic_query_params = {
        count: 5,
#        filter_content_purpose_subgroup: "news",
        fields: %w[title description image_url public_timestamp content_purpose_supergroup content_purpose_subgroup],
        order: "-public_timestamp",
        facet_organisations: "20",
      }.merge(topic_filter(params[:subtopic_slug] || params[:slug]))

      http_get("https://www.gov.uk/api/search.json?#{topic_query_params.to_query}")
    end
  end

  def taxon_filter(slug)
    taxon_id = Taxonomies.taxon_lookup(slug)
    if taxon_id.present?
      "filter_part_of_taxonomy_tree=#{taxon_id}"
    else
      ""
    end
  end

  def http_get(url)
    HTTParty.get(url)
  end

end
