require 'httparty'
require 'taxonomies'

class BrowseController < ApplicationController

  def show_mainstream_topic
    topic(params[:topic_slug], :mainstream)
  end

  def show_mainstream_subtopic
    subtopic(params[:topic_slug], params[:subtopic_slug], :mainstream)
  end

  def show_specialist_topic
    topic(params[:topic_slug], :specialist)
  end

  def show_specialist_subtopic
    subtopic(params[:topic_slug], params[:subtopic_slug], :specialist)
  end


  def show_topics
    url = "https://www.gov.uk/api/content/topic"
    content_item = http_get(url).parsed_response
    subtopics = content_item["links"]["children"].sort_by { |k| k["title"] }
    payload = {
      title: content_item["title"],
      description: content_item["description"],
      subtopics: subtopics.map {
        | subtopic | {
          title: subtopic["title"],
          link: subtopic["base_path"]
        }
      }
    }
    render json: payload
  end


private


  def topic(topic_slug, topic_type)
    if topic_type == :mainstream
      url = "https://www.gov.uk/api/content/browse/#{topic_slug}"
      content_item = http_get(url).parsed_response
      subtopic_order = content_item["details"]["ordered_second_level_browse_pages"]
      subtopics = content_item["links"]["second_level_browse_pages"]

      taxon_search_filter = (Taxonomies.taxon_filter_lookup("/browse/#{topic_slug}") || "")
      subs = subtopic_order.map{ |content_id|
        subtopic = subtopics.detect{|s| s["content_id"] == content_id }
        next if subtopic.nil?
        {
          title: subtopic["title"],
          link: subtopic["base_path"]
        }
      }.compact
    else
      url = "https://www.gov.uk/api/content/topic/#{topic_slug}"
      content_item = http_get(url).parsed_response
      subtopics = content_item["links"]["children"]
      taxon_search_filter = (Taxonomies.taxon_filter_lookup("/topic/#{topic_slug}") || "")
      subs = subtopics.map { |sub| { title: sub["title"], link: sub["base_path"] } }
    end

    payload = {
      title: content_item["title"],
      description: content_item["description"],
      subtopics: subs
    }

    if taxon_search_filter != ""
      payload[:taxon_search_filter] = taxon_search_filter
      payload[:latest_news] = latest_news_content(topic_type).map{ |news_result|
        {
          title: news_result["title"],
          description: news_result["description"],
          url: news_result["_id"],
          topic: news_result["content_purpose_supergroup"],
          subtopic: news_result["content_purpose_subgroup"],
          image_url: news_result["image_url"] || "https://assets.publishing.service.gov.uk/media/5e59279b86650c53b2cefbfe/placeholder.jpg",
          public_timestamp: news_result["public_timestamp"],
        }
      }
      payload[:organisations] = topic_organisations(topic_type)
      payload[:featured] = most_popular_content(subtopics, topic_type)
    end


    render json: payload
  end


  def subtopic(topic_slug, subtopic_slug, topic_type)
    topic_prefix = topic_type == :mainstream ? "browse" : "topic"
    url = "https://www.gov.uk/api/content/#{topic_prefix}/#{topic_slug}/#{subtopic_slug}"
    content_item = http_get(url).parsed_response

    payload = {
      title: content_item["title"],
      description: content_item["description"],
      parent:
        {
          link: content_item["links"]["parent"][0]["base_path"],
          title: content_item["links"]["parent"][0]["title"]
        }
    }

    taxon_search_filter = (Taxonomies.taxon_filter_lookup("/#{topic_prefix}/#{topic_slug}/#{subtopic_slug}") || "")
    if taxon_search_filter != ""
      payload[:taxon_search_filter] = taxon_search_filter
      payload[:latest_news] = latest_news_content(topic_type).map{ |news_result|
        {
          title: news_result["title"],
          description: news_result["description"],
          url: news_result["_id"],
          topic: news_result["content_purpose_supergroup"],
          subtopic: news_result["content_purpose_subgroup"],
          image_url: news_result["image_url"] || "https://assets.publishing.service.gov.uk/media/5e59279b86650c53b2cefbfe/placeholder.jpg",
          public_timestamp: news_result["public_timestamp"],
        }
      }
      payload[:organisations] = topic_organisations(topic_type)
      payload[:related_topics] = related_topics(content_item)
    end

    payload["subtopic_sections"] = { items: accordion_content(content_item, topic_type) }

    render json: payload
  end


  def related_topics(subtopic_details)
    (subtopic_details["links"]["second_level_browse_pages"] || []).map { |topic|
      { title: topic["title"], link: topic["base_path"] }
    }
  end

  def topic_filter(topic_path, topic_type)
    taxon_id = Taxonomies.content_id(topic_path, topic_type)
    if taxon_id.present?
      { filter_part_of_taxonomy_tree: taxon_id }
    else
     {}
    end
  end

  def accordion_content(subtopic_details, topic_type)
    groups = subtopic_details["details"]["groups"].any? ? subtopic_details["details"]["groups"] : default_group

    items_from_search = accordion_items_from_search(subtopic_details, topic_type)

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

  def accordion_items_from_search(subtopic_details, topic_type)
    accordion_items_from_search ||= begin
      max_query_count = 500
      browse_content_query_params = {
        count: max_query_count,
        fields: "title",
        order: "title",
      }
      if topic_type == :mainstream
        browse_content_query_params["filter_mainstream_browse_page_content_ids"] = subtopic_details["content_id"]
      elsif topic_type == :specialist
        browse_content_query_params["filter_specialist_sectors"] = subtopic_details["base_path"].sub("/topic/", "")
      else
        puts "Unknown topic type: #{topic_type}"
      end
      response = http_get("https://www.gov.uk/api/search.json?#{browse_content_query_params.to_query}")
      if response["total"] == max_query_count
        puts "WARNING: API returned item count limit (#{max_query_count}). There are probably more."
      end
      response["results"].map { |result| { title: result["title"].strip, link: result["_id"] } }
    end
  end

  def most_popular_content_results(subtopics, topic_type)
    most_popular_content ||= begin
      popular_content_query_params = {
        count: 3,
        fields: "title"
      }
      if topic_type == :mainstream
        popular_content_query_params["filter_mainstream_browse_pages"] =
          subtopics.map { |subtopic| subtopic["base_path"].sub("/browse/", "") }
      else
        popular_content_query_params["filter_specialist_sectors"] =
          subtopics.map { |subtopic| subtopic["base_path"].sub("/topic/", "") }
      end
      http_get("https://www.gov.uk/api/search.json?#{popular_content_query_params.to_query}")["results"]
    end
  end

  def most_popular_content(subtopics, topic_type)
    most_popular_content_results(subtopics, topic_type).map { |popular| { title: popular["title"], link: popular["_id"] } }
  end

  def latest_news_content(topic_type)
    topic_query(topic_type)["results"]
  end

  def topic_organisations(topic_type)
    # Comes from a response looking like: https://www.gov.uk/api/search.json?facet_organisations=20&count=0
    @topic_organisations ||= begin
      topic_query(topic_type)["facets"]["organisations"]["options"].map { |org_option|
        {
          title: org_option["value"]["title"],
          url: org_option["value"]["link"],
          crest: org_option["value"]["organisation_crest"],
          slug: org_option["value"]["slug"],
        }
      }
    end
  end

  def topic_query(topic_type)
    @topic_query ||= begin
      topic_path = "#{params[:topic_slug]}#{params[:subtopic_slug] ? "/":""}#{params[:subtopic_slug]}"
      topic_query_params = {
        count: 3,
        fields: %w[title description image_url public_timestamp content_purpose_supergroup content_purpose_subgroup],
        order: "-public_timestamp",
        facet_organisations: "20",
      }.merge(topic_filter(topic_path, topic_type))
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
