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
          link: subtopic["base_path"],
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
      parent_url: "/browse/#{topic_slug}",
      taxon_search_filter: (taxon_filter_lookup[subtopic_slug] || ""),
      latest_news: {
        title: latest_news_content.first["title"],
        description: latest_news_content.first["description"],
        url: latest_news_content.first["_id"],
        image_url: latest_news_content.first["image_url"] || "https://assets.publishing.service.gov.uk/media/5e59279b86650c53b2cefbfe/placeholder.jpg",
      },
      featured: most_popular_content([subtopic_details]),
      subtopic_sections: { items: accordion_content(subtopic_details) },
      related_topics: related_topics(subtopic_details)
    }

    render json: payload
  end

private

  def related_topics(subtopic_details)
    (subtopic_details["links"]["second_level_browse_pages"] || []).map { |topic|
      { title: topic["title"], link: topic["base_path"] }
    }
  end

  def topic_filter(browse_slug)
    taxon_id = taxon_lookup[browse_slug]

    if taxon_id.present?
      { filter_part_of_taxonomy_tree: taxon_id }
    else
     {}
    end
  end

  def accordion_content(subtopic_details)
    groups = subtopic_details["details"]["groups"].any? ? subtopic_details["details"]["groups"] : default_group

    groups.map { |detail|
      list = if subtopic_details["details"]["groups"].nil?
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
    accordion_items_from_search(subtopic_details).map { |child|
      "<li><a href='#{child[:link]}'>#{child[:title]}</a></li>"
    }.join
  end

  def accordion_items_from_search(subtopic_details)
    accordion_items_from_search ||= begin
      browse_content_query_params = {
        count: 100,
        filter_mainstream_browse_page_content_ids: subtopic_details["content_id"].sub("/browse/", ""),
        fields: "title",
        order: "title",
      }
      puts "https://www.gov.uk/api/search.json?#{browse_content_query_params.to_query}"
      results = HTTParty.get("https://www.gov.uk/api/search.json?#{browse_content_query_params.to_query}")["results"]
      results.map { |result| { title: result["title"].strip, link: result["_id"] } }
    end
  end

  def most_popular_content_results(subtopics)
    most_popular_content ||= begin
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
    latest_news_content ||= begin
      latest_news_query_params = {
        count: 1,
        filter_content_purpose_subgroup: "news",
        fields: %w[title description image_url],
        order: "-public_timestamp"
      }.merge(topic_filter(params[:subtopic_slug] || params[:slug]))

      latest_news_content = HTTParty.get("https://www.gov.uk/api/search.json?#{latest_news_query_params.to_query}")["results"]
    end
  end

  def taxon_filter(slug)
    taxon_id = taxon_lookup[slug]
    if taxon_id.present?
      "level_one_taxon=#{taxon_id}"
    else
      ""
    end
  end

  def taxon_lookup
    {
      "benefits" => "dded88e2-f92e-424f-b73e-6ad24a839c51",
      "entitlement" => "536f83c0-8c67-47a3-88a4-d5b1eda591ed",
      "universal-credit" => "62fcbba5-3a75-4d15-85a6-d8a80b03d57c",
      "tax-credits" => "a7f3005b-a3cd-4060-a127-725accb54f2e",
      "jobseekers-allowance" => "2a1bd1b1-5025-4313-9e5b-8352dd46f1d6",
      "disability" => "05a9527b-e6e9-4a68-8dd7-7d84e6a24eef",
      "child" => "7a1ba896-b85a-4137-81d9-ab05b7ce67dd",
      "families" => "29dbee2a-5865-489b-860f-7eef54a5165a",
      "heating" => "6c4c443c-2e11-4d25-aa93-2e3a38d9499c",
      "bereavement" => "ac7b8472-5d09-4679-9551-87847b0ac827",
      "visas-immigration" => "ba3a9702-da22-487f-86c1-8334a730e559",
      "what-you-need-to-do" => "6dc91505-fdbd-4b6b-9bd5-fef3dc8baf42",
      "eu-eea-commonwealth" => "ba3a9702-da22-487f-86c1-8334a730e559",
      "tourist-short-stay-visas" => "9480b00-dc4d-49a0-b48c-25dda8569325",
      "student-visas" => "9480b00-dc4d-49a0-b48c-25dda8569325",
      "work-visas" => "f48188df-8130-4d36-98e0-e72125d016a2",
      "family-visas" => "9480b00-dc4d-49a0-b48c-25dda8569325",
      "settle-in-the-uk" => "fef7e737-6f1a-4ef4-b844-aa24b630ad03",
      "asylum" => "08a8a69f-2825-4fe2-a4cf-c83458a5629e",
      "immigration-appeals" => "6e85c12f-f52b-41b3-93ad-59e5f19d64f6",
      "arriving-in-the-uk" => "ba3a9702-da22-487f-86c1-8334a730e559",
    }
  end

  def taxon_filter_lookup
    {
      "benefits" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51",
      "entitlement" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51&level_two_taxon=536f83c0-8c67-47a3-88a4-d5b1eda591ed",
      "universal-credit" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51&level_two_taxon=62fcbba5-3a75-4d15-85a6-d8a80b03d57c",
      "tax-credits" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51&level_two_taxon=a7f3005b-a3cd-4060-a127-725accb54f2e",
      "jobseekers-allowance" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51&level_two_taxon=2a1bd1b1-5025-4313-9e5b-8352dd46f1d6",
      "disability" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51&level_two_taxon=05a9527b-e6e9-4a68-8dd7-7d84e6a24eef",
      "child" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51&level_two_taxon=7a1ba896-b85a-4137-81d9-ab05b7ce67dd",
      "families" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51&level_two_taxon=29dbee2a-5865-489b-860f-7eef54a5165a",
      "heating" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51&level_two_taxon=6c4c443c-2e11-4d25-aa93-2e3a38d9499c",
      "bereavement" => "level_one_taxon=dded88e2-f92e-424f-b73e-6ad24a839c51&level_two_taxon=ac7b8472-5d09-4679-9551-87847b0ac827",
      "visas-immigration" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559",
      "what-you-need-to-do" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=6dc91505-fdbd-4b6b-9bd5-fef3dc8baf42",
      "eu-eea-commonwealth" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=ba3a9702-da22-487f-86c1-8334a730e559",
      "tourist-short-stay-visas" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=9480b00-dc4d-49a0-b48c-25dda8569325",
      "student-visas" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=9480b00-dc4d-49a0-b48c-25dda8569325",
      "work-visas" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=f48188df-8130-4d36-98e0-e72125d016a2",
      "family-visas" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=9480b00-dc4d-49a0-b48c-25dda8569325",
      "settle-in-the-uk" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=fef7e737-6f1a-4ef4-b844-aa24b630ad03",
      "asylum" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=08a8a69f-2825-4fe2-a4cf-c83458a5629e",
      "immigration-appeals" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=6e85c12f-f52b-41b3-93ad-59e5f19d64f6",
      "arriving-in-the-uk" => "level_one_taxon=ba3a9702-da22-487f-86c1-8334a730e559&level_two_taxon=ba3a9702-da22-487f-86c1-8334a730e559",
    }
  end
end
