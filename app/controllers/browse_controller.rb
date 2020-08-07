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

    puts "https://www.gov.uk/api/search.json?#{popular_content_query_params.to_query}"
    most_popular_content = HTTParty.get("https://www.gov.uk/api/search.json?#{popular_content_query_params.to_query}")

    dummy = {
      title: content_item["title"],
      description: content_item["description"],
      featured: most_popular_content["results"].map { |popular| { title: popular["title"], link: ["_id"] } },
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

  def accordion_content(subtopic_details)
    subtopic_details["details"]["groups"].map { |detail|
      list = accordion_list_items(detail["contents"], subtopic_details["links"]["children"])
      next if list.empty?
      {
        heading: { text: detail["name"] },
        content: { html:  "<ul class='govuk-list'>#{list}</ul>" }
      }
    }.compact
  end

  def accordion_list_items(ordered_paths, tagged_children)
    tagged_children_paths = tagged_children.map { |child| child["base_path"] }

    ordered_paths
      .select{ |path| tagged_children_paths.include? path }
      .map { |path|
        current_item = tagged_children.detect { |child| child["base_path"] == path }
        "<li><a href='#{path}'>#{current_item["title"]}</a></li>"
      }.join
  end

end
