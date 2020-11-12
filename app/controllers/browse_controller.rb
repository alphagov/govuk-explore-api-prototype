require 'httparty'
require 'taxonomies'

class BrowseController < ApplicationController



  def show
    browse_slug = params[:slug]

    url = "https://www.gov.uk/api/content/browse/#{browse_slug}"

    content_item = http_get(url).parsed_response

    subtopic_order = content_item["details"]["ordered_second_level_browse_pages"]
    subtopics = content_item["links"]["second_level_browse_pages"]

    payload = {
      title: content_item["title"],
      description: content_item["description"],
      taxon_search_filter: (Taxonomies.taxon_filter_lookup(browse_slug) || ""),
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
      subtopics: subtopic_order.map{ |content_id|

        subtopic = subtopics.detect{|s| s["content_id"] == content_id }
        next if subtopic.nil?

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

  def subtopic
    topic_slug = params[:slug]
    subtopic_slug = params[:subtopic_slug]

    subtopic_details = http_get("https://www.gov.uk/api/content/browse/#{topic_slug}/#{subtopic_slug}").parsed_response

    payload = {
      title: subtopic_details["title"],
      description: subtopic_details["description"],
      parent_url: "/browse/#{topic_slug}",
      taxon_search_filter: (Taxonomies.taxon_filter_lookup(subtopic_slug) || ""),

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
    taxon_id = Taxonomies.taxon_lookup(browse_slug)

    if taxon_id.present?
      { filter_part_of_taxonomy_tree: taxon_id }
    else
     {}
    end
  end

  def accordion_content(subtopic_details)
    groups = subtopic_details["details"]["groups"].any? ? subtopic_details["details"]["groups"] : default_group

    items_from_search = accordion_items_from_search(subtopic_details)

    groups.map { |detail|
      list = if subtopic_details["details"]["groups"].nil? || subtopic_details["details"]["groups"].empty?
        search_accordion_list_items(items_from_search)
      elsif subtopic_details["details"]["second_level_ordering"] == "alphabetical" || detail["contents"].nil?
        alphabetical_accordion_list_items(subtopic_details["links"]["children"])
      else
        curated_accordion_list_items(detail["contents"], items_from_search)
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

  def curated_accordion_list_items(ordered_paths, items_from_search)
    tagged_children_paths = items_from_search.map { |child| child[:link] }

    ordered_paths
      .select{ |path| tagged_children_paths.include? path }
      .map { |path|
        current_item = items_from_search.detect { |child| child[:link] == path }
        "<li><a href='#{path}'>#{current_item[:title]}</a></li>"
      }.join
  end

  def search_accordion_list_items(items_from_search)
    items_from_search.map { |child|
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
      # puts "https://www.gov.uk/api/search.json?#{browse_content_query_params.to_query}"
      results = http_get("https://www.gov.uk/api/search.json?#{browse_content_query_params.to_query}")["results"]
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
      http_get("https://www.gov.uk/api/search.json?#{popular_content_query_params.to_query}")["results"]
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
    topic_query["results"]
  end

  def topic_organisations
    # Comes from a response looking like: https://www.gov.uk/api/search.json?facet_organisations=20&count=0
    @topic_organisations ||= begin
      topic_query["facets"]["organisations"]["options"].map { |org_option|
        {
          title: org_option["value"]["title"],
          url: org_option["value"]["link"],
          crest: org_option["value"]["organisation_crest"],
          slug: org_option["value"]["slug"],
        }
      }
    end
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
