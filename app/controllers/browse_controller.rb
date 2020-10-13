require 'httparty'

class BrowseController < ApplicationController

  @@welfare = "dded88e2-f92e-424f-b73e-6ad24a839c51"
  @@business_and_industry = "495afdb6-47be-4df1-8b38-91c8adb1eefc"
  @@transport = "a4038b29-b332-4f13-98b1-1c9709e216bc"
  @@money = "6acc9db4-780e-4a46-92b4-1812e3c2c48a"
  @@entering_staying_uk = "ba3a9702-da22-487f-86c1-8334a730e559"
  @@work = "d0f1e5a3-c8f4-4780-8678-994f19104b21"
  @@defence_and_armed_forces="e491505c-77ae-45b2-84be-8c94b94f6a2b"
  @@childcare_parenting="206b7f3a-49b5-476f-af0f-fd27e2a68473"
  @@environment="3cf97f69-84de-41ae-bc7b-7e2cc238fa58"

  @@personal_tax = "a5c88a77-03ba-4100-bd33-7ee2ce602dc8"
  @@business_tax = "28262ae3-599c-4259-ae30-3c83a5ec02a1"
  @@rights_foreign_nationals_uk = "6e85c12f-f52b-41b3-93ad-59e5f19d64f6"
  @@visas_entry_clearance = "29480b00-dc4d-49a0-b48c-25dda8569325"
  @@refugees_asylum_human_rights="08a8a69f-2825-4fe2-a4cf-c83458a5629e"
  @@working="092348a4-b896-4f8f-a0dc-e6d4605a4904"
  @@running_a_business="8aa41155-58ff-4d7d-a11a-7e3ef42863dd"
  @@importing_exporting= "c9dedc39-8eff-4e75-ac40-bd578e312763"
  @@business_regulation="33bc0eed-62c7-4b0b-9a93-626c9e10c025"
  @@childcare_and_early_years="f1d9c348-5c5e-4fc6-9172-13a62537d3ae"
  @@food_and_farming="52ff5c99-a17b-42c4-a9d7-2cc92cccca39"
  @@business_regulation="33bc0eed-62c7-4b0b-9a93-626c9e10c025"
  @@waste_and_recycling="f4e9e92d-9192-4e17-90c6-553339bc04c3"
  @@science_and_innovation="ccb77bcc-56b4-419a-b5ce-f7c2234e0546"




  def show
    browse_slug = params[:slug]

    url = "https://www.gov.uk/api/content/browse/#{browse_slug}"
    content_item = http_get(url).parsed_response

    subtopic_order = content_item["details"]["ordered_second_level_browse_pages"]
    subtopics = content_item["links"]["second_level_browse_pages"]

    payload = {
      title: content_item["title"],
      description: content_item["description"],
      taxon_search_filter: (taxon_filter_lookup[browse_slug] || ""),
      latest_news: latest_news_content.map{ |news_result|
        {
          title: news_result["title"],
          description: news_result["description"],
          url: news_result["_id"],
          image_url: news_result["image_url"] || "https://assets.publishing.service.gov.uk/media/5e59279b86650c53b2cefbfe/placeholder.jpg",
        }
      },
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
    @latest_news_content ||= begin
      latest_news_query_params = {
        count: 5,
        filter_content_purpose_subgroup: "news",
        fields: %w[title description image_url],
        order: "-public_timestamp"
      }.merge(topic_filter(params[:subtopic_slug] || params[:slug]))

      # puts "https://www.gov.uk/api/search.json?#{latest_news_query_params.to_query}"
      latest_news_content = http_get("https://www.gov.uk/api/search.json?#{latest_news_query_params.to_query}")["results"]
    end
  end

  def taxon_filter(slug)
    taxon_id = taxon_lookup[slug]
    if taxon_id.present?
      "filter_part_of_taxonomy_tree=#{taxon_id}"
    else
      ""
    end
  end

  def taxon_lookup
    {
      # Benefits
      "benefits" => "dded88e2-f92e-424f-b73e-6ad24a839c51", # Welfare
      "entitlement" => "536f83c0-8c67-47a3-88a4-d5b1eda591ed", # Welfare > Benefits entitlement
      "universal-credit" => "62fcbba5-3a75-4d15-85a6-d8a80b03d57c", # Welfare > Universal credit
      "tax-credits" => "a7f3005b-a3cd-4060-a127-725accb54f2e", # Welfare > Tax credits
      "jobseekers-allowance" => "2a1bd1b1-5025-4313-9e5b-8352dd46f1d6", # Welfare > Jobseeker's Allowance
      "disability" => "05a9527b-e6e9-4a68-8dd7-7d84e6a24eef", # Welfare > Carers and disability benefits
      "child" => "7a1ba896-b85a-4137-81d9-ab05b7ce67dd", # Welfare > Child benefit (multiple)
      "families" => "29dbee2a-5865-489b-860f-7eef54a5165a", # Welfare > Benefits for families
      "heating" => "6c4c443c-2e11-4d25-aa93-2e3a38d9499c", # Welfare > Heating and housing benefits
      "bereavement" => "ac7b8472-5d09-4679-9551-87847b0ac827", # Welfare > Death and benefits

      # Money and Tax

      "tax" => "6acc9db4-780e-4a46-92b4-1812e3c2c48a",
      "capital-gains" => "3bc4ec93-fd86-4c66-98d0-7623cbbaa6be",
      "court-claims-debt-bankruptcy" => "7c4cf197-2dba-4a82-83e2-6c8bb332525c",
      "dealing-with-hmrc" => "b20215a9-25fb-4fa6-80a3-42e23f5352c2",
      "income-tax" => "104ee859-8278-406b-80cb-5727373e0198",
      "inheritance-tax" => "a5c88a77-03ba-4100-bd33-7ee2ce602dc8",
      "national-insurance" => "cc195f93-4244-489a-97e9-22480113c770",
      "self-assessment" => "24e91c04-21cb-479a-8f23-df0eaab31788",
      "vat" => "e04c9a5c-88e8-46e5-91d9-add405e098fb",

      # Visas and immigration

      "visas-immigration" => "ba3a9702-da22-487f-86c1-8334a730e559",
      # "what-you-need-to-do" => "", NO MATCH
      "eu-eea-commonwealth" => "06e2928c-57b1-4b8d-a06e-3dde9ce63a6f",
      "tourist-short-stay-visas" => "18c7918f-cde5-4e66-b5f4-cd15c33cc1cc",
      "student-visas" => "51b699cf-d4dc-488c-a87e-070560d37791",
      "work-visas" => "2170a0e2-603e-4385-b929-4b17b9ecc343",
      "family-visas" => "d612c61e-22f4-4922-8bb2-b04b9202126e",
      "settle-in-the-uk" => "fef7e737-6f1a-4ef4-b844-aa24b630ad03",
      "asylum" => "08a8a69f-2825-4fe2-a4cf-c83458a5629e",
      "immigration-appeals" => "e1d2032c-6a59-4a1a-919c-dc149847dffb",
      "arriving-in-the-uk" => "18c7918f-cde5-4e66-b5f4-cd15c33cc1cc",

      # work jobs and pensions

      "work" => "092348a4-b896-4f8f-a0dc-e6d4605a4904",
      "armed-forces" => "8ff8cf05-a6e6-4757-a896-4fabd9f3229a",
      "finding-job" => "21bfd8f6-3360-43f9-be42-b00002982d70",
      "time-off" => "ebeaf804-c1b1-40cd-920f-319aa2b56ba3",
      "redundancies-dismissals" => "a4d954b4-3a64-488c-a0fc-fa91ecb8cf2b",
      "working-state-pension" => "f8b6d54b-cc94-4b32-aac4-8cd344087407",
      "workplace-personal-pensions" => "a99fc39c-997a-4b1a-9e6d-8cf63a3100be",
      "contract-working-hours" => "23a712ff-23b3-4f5a-83f1-44ac679fe615",
      "tax-minimum-wage" => "ee1214e7-d14d-4975-9e08-b304642ab112",
      "rights-trade-unions" => "0ee0e4df-7b06-47e4-8f1c-242603e16577",

      # business and self-employed

      "business-and-industry" => "495afdb6-47be-4df1-8b38-91c8adb1eefc",
      # "setting-up" => "??", NO MATCH
      "business-tax" => "28262ae3-599c-4259-ae30-3c83a5ec02a1",
      "finance-support" => "ccfc50f5-e193-4dac-9d78-50b3a8bb24c5",
      "limited-company" => "8aa41155-58ff-4d7d-a11a-7e3ef42863dd",
      "expenses-employee-benefits" => "5605545e-03ca-4520-9519-163ea341bc86",
      "funding-debt" => "a1119685-ffef-4417-a3e4-116014ad4523",
      "premises-rates" => "68cc0b3c-7f80-4869-9dc7-b2ceef5f4f08",
      # "food" => "??", NO MATCH
      "imports" => "d74faafc-781d-4087-8e0c-be4216180059",
      "exports" => "efa9782b-a3d0-4ca0-9c92-3b89748175b7",
      "licences" => "8758d11e-3c6f-4b81-99e6-791a99e44363",
      # "selling-closing" => "??", NOT FOUND
      "sales-good-services-data" => "c39ac533-be2c-4460-93ba-e656793568ef",
      "childcare-providers" => "18cb575a-45a0-4ab8-8bff-12c48a2ee8d4",
      "farming" => "e2559668-cf36-47fc-8a77-2e760e12a812",
      "manufacturing" => "d34ba9b3-28d8-40d5-a2d3-f52d216c2590",
      "intellectual-property" => "d949275c-88f8-4623-a44b-eb3706651e10",
      "waste-environment" => "090c16bc-7b3e-42cd-b93c-645ab43fae30",
      "science" => "429bf677-b514-4c10-8a89-c0eee4acc7ec",
      "generating-energy" => "092c86a5-717e-4bea-be43-4a5d8695a113",
      "maritime" => "4a9ab4d7-0d03-4c61-9e16-47787cbf53cd"
    }
  end

  def taxon_filter_lookup
    {

      # Benefits

      "benefits"             => "level_one_taxon=#{@@welfare}",
      "entitlement"          => "level_one_taxon=#{@@welfare}&level_two_taxon=536f83c0-8c67-47a3-88a4-d5b1eda591ed",
      "universal-credit"     => "level_one_taxon=#{@@welfare}&level_two_taxon=62fcbba5-3a75-4d15-85a6-d8a80b03d57c",
      "tax-credits"          => "level_one_taxon=#{@@welfare}&level_two_taxon=a7f3005b-a3cd-4060-a127-725accb54f2e",
      "jobseekers-allowance" => "level_one_taxon=#{@@welfare}&level_two_taxon=2a1bd1b1-5025-4313-9e5b-8352dd46f1d6",
      "disability"           => "level_one_taxon=#{@@welfare}&level_two_taxon=05a9527b-e6e9-4a68-8dd7-7d84e6a24eef",
      "child"                => "level_one_taxon=#{@@welfare}&level_two_taxon=7a1ba896-b85a-4137-81d9-ab05b7ce67dd",
      "families"             => "level_one_taxon=#{@@welfare}&level_two_taxon=29dbee2a-5865-489b-860f-7eef54a5165a",
      "heating"              => "level_one_taxon=#{@@welfare}&level_two_taxon=6c4c443c-2e11-4d25-aa93-2e3a38d9499c",
      "bereavement"          => "level_one_taxon=#{@@welfare}&level_two_taxon=ac7b8472-5d09-4679-9551-87847b0ac827",

      # Money and tax

      "tax"                          => "level_one_taxon=#{@@money}",
      "capital-gains"                => "level_one_taxon=#{@@money}&level_two_taxon=#{@@personal_tax}&level_three_taxon=3bc4ec93-fd86-4c66-98d0-7623cbbaa6be",
      "court-claims-debt-bankruptcy" => "level_one_taxon=#{@@money}&level_two_taxon=7c4cf197-2dba-4a82-83e2-6c8bb332525c",
      "dealing-with-hmrc"            => "level_one_taxon=#{@@money}&level_two_taxon=b20215a9-25fb-4fa6-80a3-42e23f5352c2",
      "income-tax"                   => "level_one_taxon=#{@@money}&level_two_taxon=#{@@personal_tax}&level_three_taxon=104ee859-8278-406b-80cb-5727373e0198",
      "inheritance-tax"              => "level_one_taxon=#{@@money}&level_two_taxon=#{@@personal_tax}&level_three_taxon=a5c88a77-03ba-4100-bd33-7ee2ce602dc8",
      "national-insurance"           => "level_one_taxon=#{@@money}&level_two_taxon=#{@@personal_tax}&level_three_taxon=cc195f93-4244-489a-97e9-22480113c770",
      "self-assessment"              => "level_one_taxon=#{@@money}&level_two_taxon=#{@@personal_tax}&level_three_taxon=24e91c04-21cb-479a-8f23-df0eaab31788",
      "vat"                          => "level_one_taxon=#{@@money}&level_two_taxon=#{@@business_tax}&level_three_taxon=e04c9a5c-88e8-46e5-91d9-add405e098fb",


      # Visas and immigration

      "visas-immigration"        => "level_one_taxon=#{@@entering_staying_uk}}",
      # "what-you-need-to-do"      => "", NO MATCH
      "eu-eea-commonwealth"      => "level_one_taxon=#{@@entering_staying_uk}&level_two_taxon=#{@@rights_foreign_nationals_uk}&level_three_taxon=06e2928c-57b1-4b8d-a06e-3dde9ce63a6f",
      "tourist-short-stay-visas" => "level_one_taxon=#{@@entering_staying_uk}&level_two_taxon=18c7918f-cde5-4e66-b5f4-cd15c33cc1cc",
      "student-visas"            => "level_one_taxon=#{@@entering_staying_uk}&level_two_taxon=#{@@visas_entry_clearance}&level_three_taxon=51b699cf-d4dc-488c-a87e-070560d37791",
      "work-visas"               => "level_one_taxon=#{@@entering_staying_uk}&level_two_taxon=#{@@rights_foreign_nationals_uk}&level_three_taxon=2170a0e2-603e-4385-b929-4b17b9ecc343",
      "family-visas"             => "level_one_taxon=#{@@entering_staying_uk}&level_two_taxon=#{@@visas_entry_clearance}&level_three_taxon=d612c61e-22f4-4922-8bb2-b04b9202126e",
      "settle-in-the-uk"         => "level_one_taxon=#{@@entering_staying_uk}&level_two_taxon=fef7e737-6f1a-4ef4-b844-aa24b630ad03",
      "asylum"                   => "level_one_taxon=#{@@entering_staying_uk}&level_two_taxon=#{@@refugees_asylum_human_rights}",
      "immigration-appeals"      => "level_one_taxon=#{@@entering_staying_uk}&level_two_taxon=#{@@refugees_asylum_human_rights}&level_three_taxon=e1d2032c-6a59-4a1a-919c-dc149847dffb",
      "arriving-in-the-uk"       => "level_one_taxon=#{@@entering_staying_uk}&level_two_taxon=18c7918f-cde5-4e66-b5f4-cd15c33cc1cc",


      # work jobs and pensions

      # Work > Working, jobs and pensions
      "work"                        => "level_one_taxon=#{@@work}&level_two_taxon=#{@@working}",
      "armed-forces"                => "level_one_taxon=#{@@defence_and_armed_forces}&level_two_taxon=8ff8cf05-a6e6-4757-a896-4fabd9f3229a",
      "finding-job"                 => "level_one_taxon=#{@@work}&level_two_taxon=#{@@working}&level_three_taxon=21bfd8f6-3360-43f9-be42-b00002982d70",
      "time-off"                    => "level_one_taxon=#{@@work}&level_two_taxon=#{@@working}&level_three_taxon=ebeaf804-c1b1-40cd-920f-319aa2b56ba3",
      "redundancies-dismissals"     => "level_one_taxon=#{@@work}&level_two_taxon=#{@@working}&level_three_taxon=a4d954b4-3a64-488c-a0fc-fa91ecb8cf2b",
      "working-state-pension"       => "level_one_taxon=#{@@work}&level_two_taxon=#{@@working}&level_three_taxon=f8b6d54b-cc94-4b32-aac4-8cd344087407",
      "workplace-personal-pensions" => "level_one_taxon=#{@@work}&level_two_taxon=#{@@working}&level_three_taxon=a99fc39c-997a-4b1a-9e6d-8cf63a3100be",
      "contract-working-hours"      => "level_one_taxon=#{@@work}&level_two_taxon=#{@@working}&level_three_taxon=23a712ff-23b3-4f5a-83f1-44ac679fe615",
      "tax-minimum-wage"            => "level_one_taxon=#{@@work}&level_two_taxon=#{@@working}&level_three_taxon=ee1214e7-d14d-4975-9e08-b304642ab112",
      "rights-trade-unions"         => "level_one_taxon=#{@@work}&level_two_taxon=#{@@working}&level_three_taxon=0ee0e4df-7b06-47e4-8f1c-242603e16577",

      # business and self-employed

      # Business and industry
      "business-and-industry" => "level_one_taxon=#{@@business_and_industry}",
      #  "setting-up" => "??", NO MATCH
      "business-tax"               => "level_one_taxon=#{@@money}&level_two_taxon=#{@@business_tax}",
      "finance-support"            => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@running_a_business}&level_three_taxon=ccfc50f5-e193-4dac-9d78-50b3a8bb24c5",
      "limited-company"            => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@running_a_business}",
      "expenses-employee-benefits" => "level_one_taxon=#{@@money}&level_two_taxon=5605545e-03ca-4520-9519-163ea341bc86",
      "funding-debt"               => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@running_a_business}&level_three_taxon=a1119685-ffef-4417-a3e4-116014ad4523",
      "premises-rates"             => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@running_a_business}&level_three_taxon=68cc0b3c-7f80-4869-9dc7-b2ceef5f4f08",
      # "food" => "??", NO MATCH
      "imports" => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@importing_exporting}&level_three_taxon=d74faafc-781d-4087-8e0c-be4216180059",
      "exports" => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@importing_exporting}&level_three_taxon=efa9782b-a3d0-4ca0-9c92-3b89748175b7",
      "licences" => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@running_a_business}&level_three_taxon=8758d11e-3c6f-4b81-99e6-791a99e44363",
      # "selling-closing" => "", NOT FOUND
      "sales-good-services-data" => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@business_regulation}&level_three_taxon=c39ac533-be2c-4460-93ba-e656793568ef",
      "childcare-providers"      => "level_one_taxon=#{@@childcare_parenting}&level_two_taxon=#{@@childcare_and_early_years}&level_three_taxon=18cb575a-45a0-4ab8-8bff-12c48a2ee8d4",
      "farming"                  => "level_one_taxon=#{@@environment}&level_two_taxon=#{@@food_and_farming}&level_three_taxon=e2559668-cf36-47fc-8a77-2e760e12a812",
      "manufacturing"            => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=d34ba9b3-28d8-40d5-a2d3-f52d216c2590",
      "intellectual-property"    => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@business_regulation}&level_three_taxon=d949275c-88f8-4623-a44b-eb3706651e10",
      "waste-environment"        => "level_one_taxon=#{@@environment}&level_two_taxon=#{@@waste_and_recycling}&level_three_taxon=090c16bc-7b3e-42cd-b93c-645ab43fae30",
      "science"                  => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@science_and_innovation}&level_three_taxon=429bf677-b514-4c10-8a89-c0eee4acc7ec",
      "generating-energy"        => "level_one_taxon=#{@@business_and_industry}&level_two_taxon=#{@@business_regulation}&level_three_taxon=092c86a5-717e-4bea-be43-4a5d8695a113",
      "maritime"                 => "level_one_taxon=#{@@transport}&level_two_taxon=4a9ab4d7-0d03-4c61-9e16-47787cbf53cd"
    }
  end

  def http_get(url)
    HTTParty.get(url)
  end
end
