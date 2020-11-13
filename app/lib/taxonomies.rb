require 'httparty'

module Taxonomies


  class << self

    def taxon_filter_lookup(ms_topic_path)
      qsp = ["level_one_taxon=", "level_two_taxon=", "level_three_taxon=", "level_four_taxon=", "level_five_taxon=", "level_six_taxon=", "level_seven_taxon=", "level_eight_taxon=", "level_nine_taxon="]
      taxon_path =
        @@MAP["/browse/#{ms_topic_path}"].map(&method(:taxon_content_id))
      qsp
        .zip(taxon_path)
        .filter { |pair| pair[1] != nil }
        .map { |z| z.flatten.join }
        .join "&"
    end

    def mainstream_content_id(topic_path)
      results = http_get("https://www.gov.uk/api/content/browse/#{topic_path}");
      results["content_id"]
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
        "/browse/visas-immigration" => ["entering-staying-uk"],
#        "/browse/visas-immigration/what-you-need-to-do" => [],
        "/browse/visas-immigration/eu-eea-commonwealth" => ["entering-staying-uk", "entering-staying-uk/rights-foreign-nationals-uk", "entering-staying-uk/rights-eu-eea-citizens"],
        "/browse/visas-immigration/tourist-short-stay-visas" => ["entering-staying-uk", "entering-staying-uk/travel-identity-documents-for-foreign-nationals"],
        "/browse/visas-immigration/family-visas" => ["entering-staying-uk", "/entering-staying-uk/visas-entry-clearance", "entering-staying-uk/family-visas"],
        "/browse/visas-immigration/immigration-appeals" => ["entering-staying-uk", "entering-staying-uk/refugees-asylum-human-rights", "entering-staying-uk/asylum-decisions-appeals"], # one of 2
        "/browse/visas-immigration/settle-in-the-uk" => ["entering-staying-uk", "entering-staying-uk/permanent-stay-uk"],
        "/browse/visas-immigration/asylum/student-visas" => ["entering-staying-uk", "entering-staying-uk/visas-entry-clearance", "entering-staying-uk/student-visas" ],
        "/browse/visas-immigration/arriving-in-the-uk" => ["entering-staying-uk", "entering-staying-uk/travel-identity-documents-for-foreign-nationals"],
        "/browse/visas-immigration/work-visas" => ["entering-staying-uk", "entering-staying-uk/rights-foreign-nationals-uk", "/entering-staying-uk/Foreign-nationals-working-in-UK"],

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
        "/browse/benefits/entitlement" => ["welfare", "entitlement"],
        "/browse/benefits/universal-credit" => ["welfare", "universal-credit"],
        "/browse/benefits/tax-credits" => ["welfare", "tax-credits"],
        "/browse/benefits/jobseekers-allowance" => ["welfare", "jobseekers-allowance"],
        "/browse/benefits/disability" => ["welfare", "disability"],
        "/browse/benefits/child" => ["welfare", "child-benefit"],
        "/browse/benefits/families" => ["welfare", "families"],
        "/browse/benefits/heating" => ["welfare", "heating"],
        "/browse/benefits/bereavement" => ["welfare", "bereavement"]
      }
  end
end
