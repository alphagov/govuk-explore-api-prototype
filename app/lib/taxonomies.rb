require 'httparty'

module Taxonomies


  class << self

    def taxon_filter_lookup(topic_path)
      qsp = ["level_one_taxon=", "level_two_taxon=", "level_three_taxon=", "level_four_taxon=", "level_five_taxon=", "level_six_taxon=", "level_seven_taxon=", "level_eight_taxon=", "level_nine_taxon="]
      taxon_path = @@MAP[topic_path]
      if taxon_path.nil?
        puts "Warning: topic #{topic_path} not found in taxon map"
        return ""
      end
      taxon_path_uuids = taxon_path.map(&method(:taxon_content_id))
      qsp
        .zip(taxon_path_uuids)
        .filter { |pair| pair[1] != nil }
        .map { |z| z.flatten.join }
        .join "&"
    end

    def content_id(topic_path, topic_type)
      prefix = topic_type == :mainstream ? "browse" : "topic"
      taxon_content_id(@@MAP["/#{prefix}/#{topic_path}"].last)
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

        "/browse/visas-immigration" => ["entering-staying-uk"],
#        "/browse/visas-immigration/what-you-need-to-do" => [],
        "/browse/visas-immigration/eu-eea-commonwealth" => ["entering-staying-uk", "entering-staying-uk/rights-foreign-nationals-uk", "entering-staying-uk/rights-eu-eea-citizens"],
        "/browse/visas-immigration/tourist-short-stay-visas" => ["entering-staying-uk", "entering-staying-uk/travel-identity-documents-for-foreign-nationals"],
        "/browse/visas-immigration/family-visas" => ["entering-staying-uk", "entering-staying-uk/visas-entry-clearance", "entering-staying-uk/family-visas"],
        "/browse/visas-immigration/immigration-appeals" => ["entering-staying-uk", "entering-staying-uk/refugees-asylum-human-rights", "entering-staying-uk/asylum-decisions-appeals"], # one of 2
        "/browse/visas-immigration/settle-in-the-uk" => ["entering-staying-uk", "entering-staying-uk/permanent-stay-uk"],
        "/browse/visas-immigration/asylum/student-visas" => ["entering-staying-uk", "entering-staying-uk/visas-entry-clearance", "entering-staying-uk/student-visas" ],
        "/browse/visas-immigration/arriving-in-the-uk" => ["entering-staying-uk", "entering-staying-uk/travel-identity-documents-for-foreign-nationals"],
        "/browse/visas-immigration/work-visas" => ["entering-staying-uk", "entering-staying-uk/rights-foreign-nationals-uk", "entering-staying-uk/Foreign-nationals-working-in-UK"],

        "/browse/tax" => ["money"],
        "/browse/tax/capital-gains" => ["money", "money/personal-tax"],
        "/browse/tax/court-claims-debt-bankruptcy" => ["money", "money/court-claims-debt-bankruptcy"],
        "/browse/tax/dealing-with-hmrc" => ["money", "money/dealing-with-hmrc"],
        "/browse/tax/income-tax" => ["money", "money/personal-tax", "money/personal-tax/income-tax" ],
        "/browse/tax/inheritance-tax" => ["money", "money/personal-tax-inheritance-tax"],
        "/browse/tax/national-insurance" => ["money", "money/personal-tax", "money/national-insurance"],
        "/browse/tax/self-assessment" => ["money", "money/personal-tax", "money/self-assessment"],
        "/browse/tax/vat" => ["money", "money/business-tax", "money/vat"],

        "/browse/benefits" => ["welfare"],
        "/browse/benefits/entitlement" => ["welfare", "welfare/entitlement"],
        "/browse/benefits/universal-credit" => ["welfare", "welfare/universal-credit"],
        "/browse/benefits/tax-credits" => ["welfare", "welfare/tax-credits"],
        "/browse/benefits/jobseekers-allowance" => ["welfare", "welfare/jobseekers-allowance"],
        "/browse/benefits/disability" => ["welfare", "welfare/disability"],
        "/browse/benefits/child" => ["welfare", "welfare/child-benefit"],
        "/browse/benefits/families" => ["welfare", "welfare/families"],
        "/browse/benefits/heating" => ["welfare", "welfare/heating"],
        "/browse/benefits/bereavement" => ["welfare", "welfare/bereavement"],

        "/browse/working" => ["work", "employment/working"],
        "/browse/working/armed-forces" => ["defence-and-armed-forces", "defence/working-armed-forces"],
        "/browse/working/finding-job" => ["work", "employment/working", "employment/finding-job"],
        "/browse/working/time-off"  => ["work", "employment/working", "employment/time-off"],
        "/browse/working/redundancies-dismissals"  => ["work", "employment/working", "employment/redundancies-dismissals"],
        "/browse/working/state-pension"  => ["work", "employment/working", "employment/working-state-pension"],
        "/browse/working/workplace-personal-pensions"  => ["work", "employment/working", "employment/workplace-personal-pensions"],
        "/browse/working/contract-working-hours"  => ["work", "employment/working", "employment/contract-working-hours"],
        "/browse/working/tax-minimum-wage"  => ["work", "employment/working", "employment/tax-minimum-wage"],
        "/browse/working/rights-trade-unions"  => ["work", "employment/working", "employment/rights-trade-unions"],

        #### SPECIALIST TOPICS ###########

        "/topic/benefits-credits" => ["welfare"],
        "/topic/benefits-credits/child-benefit" => ["welfare", "welfare/child-benefit"], # One of 2
        "/topic/benefits-credits/tax-credits" => ["welfare", "welfare/tax-credits"],
        "/topic/benefits-credits/universal-credit" =>  ["welfare", "welfare/universal-credit"],

        "/topic/animal-welfare" => ["environment", "environment/wildlife-animals-biodiversity-and-ecosystems", "environment/animal-welfare"], # TBC
        "/topic/animal-welfare/pets" => ["environment", "environment/wildlife-animals-biodiversity-and-ecosystems", "environment/pets"]
      }
  end
end
