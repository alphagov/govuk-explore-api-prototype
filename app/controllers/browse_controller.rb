require 'httparty'

class BrowseController < ApplicationController

  def show
    browse_slug = params[:slug]

    url = "https://www.gov.uk/api/content/browse/#{browse_slug}"
    content_item = HTTParty.get(url).parsed_response

    subtopic_order = content_item["details"]["ordered_second_level_browse_pages"]
    subtopics = content_item["links"]["second_level_browse_pages"]

    payload = {
      title: content_item["title"],
      description: content_item["description"],
      latest_news: {
        title: latest_news_content.first["title"],
        description: latest_news_content.first["description"],
        url: latest_news_content.first["_id"],
        image_url: latest_news_content.first["image_url"] || "https://assets.publishing.service.gov.uk/media/5e59279b86650c53b2cefbfe/placeholder.jpg",
      },
      featured: most_popular_content(subtopics),
      subtopics: subtopic_order.map{ |content_id|

        subtopic = subtopics.detect{|s| s["content_id"] == content_id }
        next if subtopic.nil?

        subtopic_details = HTTParty.get(subtopic["api_url"]).parsed_response

        content =  accordion_content(subtopic_details)

        {
          title: subtopic["title"],
          link: "/browse/" +subtopic["base_path"],
          subtopic_sections: {
            items: content
          }
        }
      }.compact
    }

    render json: payload
  end

  def subtopic
    topic_slug = params[:slug]
    subtopic_slug = params[:subtopic_slug]

    subtopic_details = HTTParty.get("https://www.gov.uk/api/content/browse/#{topic_slug}/#{subtopic_slug}").parsed_response

    payload = {
      title: subtopic_details["title"],
      description: subtopic_details["description"],
      latest_news: {
        title: latest_news_content.first["title"],
        description: latest_news_content.first["description"],
        url: latest_news_content.first["_id"],
        image_url: latest_news_content.first["image_url"] || "https://assets.publishing.service.gov.uk/media/5e59279b86650c53b2cefbfe/placeholder.jpg",
      },
      featured: most_popular_content([subtopic_details]),
      subtopic_sections: { items: accordion_content(subtopic_details) }
    }

    render json: payload
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
    puts subtopic_details["base_path"]
    groups = subtopic_details["details"]["groups"].any? ? subtopic_details["details"]["groups"] : default_group

    groups.map { |detail|
      list = if subtopic_details["links"]["children"].nil?
        search_accordion_list_items(subtopic_details)
      elsif subtopic_details["details"]["second_level_ordering"] == "alphabetical" || detail["contents"].nil?
        alphabetical_accordion_list_items(subtopic_details["links"]["children"])
      else
        curated_accordion_list_items(detail["contents"], subtopic_details["links"]["children"])
      end

      next if list.empty?
      {
        heading: { text: detail["name"] || "A to Z" },
        content: { html:  "<ul class='govuk-list'>#{list}</ul>" }
      }
    }.compact
  end

  def default_group
    [{ name: "A to Z" }]
  end

  def alphabetical_accordion_list_items(tagged_children)
    tagged_children.sort_by { |child| child["title"] }.map { |child|
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

  def search_accordion_list_items(subtopic_details)
    accordion_items_from_search(subtopic_details).sort_by { |child| child["title"] }.map { |child|
      "<li><a href='#{child[:link]}'>#{child[:title]}</a></li>"
    }.join
  end

  def accordion_items_from_search(subtopic_details)
    @accordion_items_from_search ||= begin
      browse_content_query_params = {
        count: 3,
        filter_mainstream_browse_pages: subtopic_details["base_path"].sub("/browse/", ""),
        fields: "title"
      }
      results = HTTParty.get("https://www.gov.uk/api/search.json?#{browse_content_query_params.to_query}")["results"]
      results.map { |result| { title: result["title"], link: result["_id"] } }
    end
  end

  def most_popular_content_results(subtopics)
    @most_popular_content ||= begin
      popular_content_query_params = {
        count: 3,
        filter_mainstream_browse_pages: subtopics.map { |subtopic| subtopic["base_path"].sub("/browse/", "") },
        fields: "title"
      }
      HTTParty.get("https://www.gov.uk/api/search.json?#{popular_content_query_params.to_query}")["results"]
    end
  end

  def most_popular_content(subtopics)
    content = most_popular_content_results(subtopics).map { |popular| { title: popular["title"], link: popular["_id"] } }
    if params[:slug] == "benefits"
      content[1] = { title: "Benefits: report a change in your circumstances", link: "/report-benefits-change-circumstances" }
    end
    content
  end

  def latest_news_content
    @latest_news_content ||= begin
      latest_news_query_params = {
        count: 1,
        filter_content_purpose_supergroup: "news_and_communications",
        fields: %w[title description image_url],
        order: "-public_timestamp"
      }.merge(topic_filter(params[:slug]))

      latest_news_content = HTTParty.get("https://www.gov.uk/api/search.json?#{latest_news_query_params.to_query}")["results"]
    end
  end
end
