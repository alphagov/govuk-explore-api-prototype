require 'httparty'

class BrowseController < ApplicationController

  def show
    browse_slug = params[:slug]

    url = "https://www.gov.uk/api/content/browse/#{browse_slug}"
    content_item = HTTParty.get(url).parsed_response

    subtopic_order = content_item["details"]["ordered_second_level_browse_pages"]
    subtopics = content_item["links"]["second_level_browse_pages"]

    popular_content_query_params = {
      count: 3,
      filter_mainstream_browse_pages: subtopics.map { |subtopic| subtopic["base_path"].sub!("/browse/", "") },
      fields: "title"
    }

    latest_news_query_params = {
      count: 1,
      filter_content_purpose_supergroup: "news_and_communications",
      fields: %w[title description image_url],
      order: "-public_timestamp"
    }.merge(topic_filter(browse_slug))

    most_popular_content = HTTParty.get("https://www.gov.uk/api/search.json?#{popular_content_query_params.to_query}")["results"]
    latest_news_content = HTTParty.get("https://www.gov.uk/api/search.json?#{latest_news_query_params.to_query}")["results"]

    dummy = {
      title: content_item["title"],
      description: content_item["description"],
      latest_news: {
        title: latest_news_content.first["title"],
        description: latest_news_content.first["description"],
        url: latest_news_content.first["_id"],
        image_url: latest_news_content.first["image_url"] || "https://assets.publishing.service.gov.uk/media/5e59279b86650c53b2cefbfe/placeholder.jpg",
      },
      featured: most_popular_content.map { |popular| { title: popular["title"], link: popular["_id"] } },
      subtopics: subtopic_order.map{ |content_id|

        subtopic = subtopics.detect{|s| s["content_id"] == content_id }
        next if subtopic.nil?

        subtopic_details = HTTParty.get(subtopic["api_url"]).parsed_response

        content =  accordion_content(subtopic_details)

        {
          title: subtopic["title"],
          subtopic_sections: {
            items: content
          }
        }
      }.compact
    }

    render json: dummy
  end

private

  def topic_filter(browse_slug)
    if browse_slug == "benefits"
      { filter_part_of_taxonomy_tree: "dded88e2-f92e-424f-b73e-6ad24a839c51"}
    elsif browse_slug == "visas-immigration"
      { filter_part_of_taxonomy_tree: "ba3a9702-da22-487f-86c1-8334a730e559" }
    else
     {}
    end
  end

  def accordion_content(subtopic_details)
    subtopic_details["details"]["groups"].map { |detail|
      # list = if subtopic_details["details"]["second_level_ordering"] == "alphabetical"
      #   alphabetical_accordion_list_items(subtopic_details["links"]["children"])
      # else
list = curated_accordion_list_items(detail["contents"], subtopic_details["links"]["children"])
      # end

      next if list.empty?
      {
        heading: { text: detail["name"] },
        content: { html:  "<ul class='govuk-list'>#{list}</ul>" }
      }
    }.compact
  end

  def alphabetical_accordion_list_items(tagged_children)
    tagged_children.map { |child|
      "<li><a href='#{child["base_path"]}'>#{child["title"]}</a></li>"
    }.join
  end

  def curated_accordion_list_items(ordered_paths, tagged_children)
    tagged_children_paths = tagged_children.map { |child| child["base_path"] }

    ordered_paths
      .select{ |path| tagged_children_paths.include? path }
      .map { |path|
        current_item = tagged_children.detect { |child| child["base_path"] == path }
        "<li><a href='#{path}'>#{current_item["title"]}</a></li>"
      }.join
  end

end
