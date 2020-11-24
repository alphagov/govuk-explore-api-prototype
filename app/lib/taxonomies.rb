require 'httparty'

module Taxonomies


  class << self

    def taxon_filter_lookup(topic_path)
      qsp = ["level_one_taxon=", "level_two_taxon=", "level_three_taxon=", "level_four_taxon=", "level_five_taxon=", "level_six_taxon=", "level_seven_taxon=", "level_eight_taxon=", "level_nine_taxon="]

      taxon_path_uuids = []

      taxon = @@MAP[topic_path]
      if taxon.nil?
        puts "Warning: topic #{topic_path} not found in taxon map"
        return ""
      end

      while true
        results = http_get("https://www.gov.uk/api/content/#{taxon}")
        taxon_path_uuids.insert(0, results["content_id"])
        parent_taxons = results["links"]["parent_taxons"]
        if parent_taxons.nil?
          break
        end
        taxon = parent_taxons[0]["base_path"]
      end

      qsp
        .zip(taxon_path_uuids)
        .filter { |pair| pair[1] != nil }
        .map { |z| z.flatten.join }
        .join "&"
    end

    def content_id(topic_path, topic_type)
      prefix = topic_type == :mainstream ? "browse" : "topic"
      taxon_content_id(@@MAP["/#{prefix}/#{topic_path}"])
    end

    private

    def http_get(url)
      HTTParty.get(url)
    end


    def taxon_content_id(taxon_path)
      results = http_get("https://www.gov.uk/api/content/#{taxon_path}");
      results["content_id"]
    end

    @@MAP =
      {

        #### MAINSTREAM TOPICS ###########

        "/browse/visas-immigration" => "entering-staying-uk",
#        "/browse/visas-immigration/what-you-need-to-do" => "",
        "/browse/visas-immigration/eu-eea-commonwealth" => "entering-staying-uk/rights-eu-eea-citizens",
        "/browse/visas-immigration/tourist-short-stay-visas" =>  "entering-staying-uk/travel-identity-documents-for-foreign-nationals",
        "/browse/visas-immigration/family-visas" =>  "entering-staying-uk/family-visas",
        "/browse/visas-immigration/immigration-appeals" =>  "entering-staying-uk/asylum-decisions-appeals", # one of 2
        "/browse/visas-immigration/settle-in-the-uk" =>  "entering-staying-uk/permanent-stay-uk",
        "/browse/visas-immigration/asylum/student-visas" =>  "entering-staying-uk/student-visas" ,
        "/browse/visas-immigration/arriving-in-the-uk" =>  "entering-staying-uk/travel-identity-documents-for-foreign-nationals",
        "/browse/visas-immigration/work-visas" => "entering-staying-uk/Foreign-nationals-working-in-UK",

        "/browse/tax" => "money",
        "/browse/tax/capital-gains" => "money/personal-tax",
        "/browse/tax/court-claims-debt-bankruptcy" =>  "money/court-claims-debt-bankruptcy",
        "/browse/tax/dealing-with-hmrc" =>  "money/dealing-with-hmrc",
        "/browse/tax/income-tax" =>  "money/personal-tax/income-tax" ,
        "/browse/tax/inheritance-tax" =>  "money/personal-tax-inheritance-tax",
        "/browse/tax/national-insurance" =>  "money/national-insurance",
        "/browse/tax/self-assessment" =>  "money/self-assessment",
        "/browse/tax/vat" => "money/vat",

        "/browse/benefits" => "welfare",
        "/browse/benefits/entitlement" =>  "welfare/entitlement",
        "/browse/benefits/universal-credit" =>  "welfare/universal-credit",
        "/browse/benefits/tax-credits" =>  "welfare/tax-credits",
        "/browse/benefits/jobseekers-allowance" =>  "welfare/jobseekers-allowance",
        "/browse/benefits/disability" =>  "welfare/disability",
        "/browse/benefits/child" =>  "welfare/child-benefit",
        "/browse/benefits/families" =>  "welfare/families",
        "/browse/benefits/heating" =>  "welfare/heating",
        "/browse/benefits/bereavement" =>  "welfare/bereavement",

        "/browse/working" =>  "employment/working",
        "/browse/working/armed-forces" =>  "defence/working-armed-forces",
        "/browse/working/finding-job" =>  "employment/finding-job",
        "/browse/working/time-off"  =>  "employment/time-off",
        "/browse/working/redundancies-dismissals"  =>  "employment/redundancies-dismissals",
        "/browse/working/state-pension"  =>  "employment/working-state-pension",
        "/browse/working/workplace-personal-pensions"  =>  "employment/workplace-personal-pensions",
        "/browse/working/contract-working-hours"  =>  "employment/contract-working-hours",
        "/browse/working/tax-minimum-wage"  =>  "employment/tax-minimum-wage",
        "/browse/working/rights-trade-unions"  =>  "employment/rights-trade-unions",

        #### SPECIALIST TOPICS ###########

        # Animal welfare
        "/topic/animal-welfare" => "environment/animal-welfare", # TBC
        "/topic/animal-welfare/pets" => "environment/pets",

        # Benefits
        "/topic/benefits-credits" => "welfare",
        "/topic/benefits-credits/child-benefit" => "welfare/child-benefit",
        "/topic/benefits-credits/tax-credits" => "welfare/tax-credits",
        "/topic/benefits-credits/universal-credit" => "welfare/universal-credit",

        # Business and enterprise
        "/topic/business-enterprise" => "business-and-industry",
        "/topic/business-enterprise/business-auditing-accounting-reporting" => "business-and-industry/business-auditing-accounting-reporting",
        "/topic/business-enterprise/european-regional-development-funding" => "business/management-of-the-european-regional-development-fund",
        "/topic/business-enterprise/export-finance" => "business-and-industry/export-finance",
        "/topic/business-enterprise/farming" => "environment",
        "/topic/business-enterprise/licensing" => "business-and-industry/business-and-industry/business-licensing",
        "/topic/business-enterprise/manufacturing" => "business-and-industry/manufacturing",
        "/topic/business-enterprise/scientific-research-and-development" => "business-and-industry/scientific-research-and-development",
        "/topic/business-enterprise/importing-exporting" => "business-and-industry/trade-restrictions-on-exports",

        # Business tax
        "/topic/business-tax" => "money/business-tax",
        "/topic/business-tax/aggregates-levy" => "money/aggregates-levy",
        "/topic/business-tax/air-passenger-duty" => "transport/air-passenger-duty",
        "/topic/business-tax/alcohol-duties" => "money/alcohol-duties",
        "/topic/business-tax/capital-allowances" => "money/capital-allowances",
        "/topic/business-tax/climate-change-levy" => "money/climate-change-levy",
        "/topic/business-tax/construction-industry-scheme" => "money/construction-industry-scheme",
        "/topic/business-tax/corporation-tax" => "money/corporation-tax",
        "/topic/business-tax/digital-services-tax" => "", # No match
        "/topic/business-tax/employment-related-securities" => "money/employment-related-securities",
        "/topic/business-tax/fuel-duty" => "money/fuel-duty",
        "/topic/business-tax/gambling-duties" => "money/gambling-duties", # one of 2 matches
        "/topic/business-tax/import-export" => "environment/producing-distributing-food-import-export",
        "/topic/business-tax/insurance-premium-tax" => "money/business-tax-insurance-premium-tax-paying-insurance-premium-tax", # One of 2 matches
        "/topic/business-tax/international-tax" => "money/international-tax",
        "/topic/business-tax/investment-schemes" => "money/investment-schemes",
        "/topic/business-tax/landfill-tax" => "money/landfill-tax",
        "/topic/business-tax/large-midsize-business-guidance" => "money/large-midsize-business",
        "/topic/business-tax/life-insurance-policies" => "money/life-insurance-policies",
        "/topic/business-tax/money-laundering-regulations" => "money/dealing-with-hmrc-tax-agent-guidance-money-laundering-regulations",
        "/topic/business-tax/ir35" => "money/ir35",
        "/topic/business-tax/paye" => "money/dealing-with-hmrc-paying-hmrc-paye", # 1 of 2
        "/topic/business-tax/pension-scheme-administration" => "money/pension-scheme-administration",
        "/topic/business-tax/self-employed" => "employment/self-employed",
        "/topic/business-tax/soft-drinks-industry-levy" => "", # No match
        "/topic/business-tax/stamp-taxes" => "money/stamp-taxes",
        "/topic/business-tax/stamp-duty-on-shares" => "money/stamp-duty-on-shares",
        "/topic/business-tax/tobacco-products-duty" => "money/tobacco-products-duty",
        "/topic/business-tax/vat" => "money/vat"
      }
  end
end
