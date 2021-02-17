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

        # Benefits
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


        # Births, deaths, marriages and care
        "/browse/births-deaths-marriages" => "life-circumstances",
        "/browse/births-deaths-marriages/register-offices" => "life-circumstances/register-offices",
        "/browse/births-deaths-marriages/child" => "welfare/child-benefit",
        "/browse/births-deaths-marriages/death" => "life-circumstances/death",
        "/browse/births-deaths-marriages/child-adoption" => "life-circumstances/child-adoption",
        "/browse/births-deaths-marriages/lasting-power-attorney" => "life-circumstances/lasting-power-attorney",
        "/browse/births-deaths-marriages/marriage-divorce" => "life-circumstances/marriage-divorce",


        # Business and self employed
        "/browse/business/" => "business-and-industry",
        #        "/browse/business/setting-up" => "", # no match
        "/browse/business/business-tax" => "money/business-tax",
        "/browse/business/finance-support" => "business/finance-support",
        "/browse/business/limited-company" => "business-and-industry/running-a-business",
        "/browse/business/expenses-employee-benefits" => "money/expenses-employee-benefits",
        "/browse/business/funding-debt" => "business-and-industry/business-debt-and-bankruptcy",
        "/browse/business/premises-rates" => "business/premises-rates",
        #        "/browse/business/food" => "", # No match
        "/browse/business/imports" => "business-and-industry/importing",
        "/browse/business/exports" => "business-and-industry/exporting",
        "/browse/business/licences" => "business-and-industry/business-licensing",
        "/browse/business/selling-closing" => "business-and-industry/company-closure-administration-liquidation-and-insolvency",
        "/browse/business/sale-goods-services-data" => "crime-justice-and-law/data-protection",
        "/browse/business/childcare-providers" => "childcare-parenting/providing-childcare",
        "/browse/business/farming" => "environment/food-and-farming-industry",
        "/browse/business/manufacturing" => "business-and-industry/manufacturing",
        "/browse/business/intellectual-property" => "business/intellectual-property",
        "/browse/business/waste-environment" => "environment/waste-environment",
        "/browse/business/science" => "business-and-industry/scientific-research-and-development",
        "/browse/business/generating-energy" => "business-and-industry/energy-industry-and-infrastructure-licensing-and-regulation",
        "/browse/business/maritime" => "transport/maritime-and-shipping",

        # Childcare and parenting
        "/browse/childcare-parenting" => "childcare-parenting",
        "/browse/childcare-parenting/pregnancy-birth" => "childcare-parenting/pregnancy-and-birth",
        "/browse/childcare-parenting/fostering-adoption-surrogacy" => "childcare-parenting/adoption-fostering-and-surrogacy",
        "/browse/childcare-parenting/financial-help-children" => "childcare-parenting/financial-help-if-you-have-children",
        "/browse/childcare-parenting/childcare" => "childcare-parenting/childcare-and-early-years",
        "/browse/childcare-parenting/schools-education" => "education/starting-and-attending-school",
        "/browse/childcare-parenting/divorce-separation-legal" => "childcare-parenting/divorce-separation-and-legal-issues",

        # Citizenship and living in the UK
        "browse/citizenship" => "entering-staying-uk",
        "browse/citizenship/citizenship" => "entering-staying-uk/citizenship",
        "browse/citizenship/charities-honours" => "society-and-culture/charities-honours",
        "browse/citizenship/government" => "government/democracy",
        "browse/citizenship/voting" => "government/voting",

        # Crime, justice and the law
        "browse/justice" => "crime-justice-and-law",
        "browse/justice/courts-sentencing-tribunals" => "crime-justice-and-law/courts-sentencing-tribunals",
        "browse/justice/prisons-probation" => "crime-justice-and-law/prisons-probation",
        "browse/justice/reporting-crimes-compensation" => "crime-justice-and-law/reporting-crimes-compensation",
        "browse/justice/young-people" => "crime-justice-and-law/young-people-and-the-law",
        "browse/justice/rights" => "crime-justice-and-law/rights",

        # Disabled people
        "browse/disabilities" => "health-and-social-care/disabilities",
        "browse/disabilities/benefits" => "health-and-social-care/disabilities-benefits",
        "browse/disabilities/carers" => "health-and-social-care/disabilities-carers",
        "browse/disabilities/equipement" => "health-and-social-care/disabilities-equipment",
        "browse/disabilities/rights" => "health-and-social-care/disabilities-rights",
        "browse/disabilities/work" => "employment/work",

        # Driving and transport

        # Education and learning

        # Employing people
        "/browse/employing-people" => "business-and-industry/employing-people",
        "/browse/employing-people/contracts" => "",
        "/browse/employing-people/dismissals-redundancies" => "business-and-industry/employing-people",
        "/browse/employing-people/health-safety" => "",
        "/browse/employing-people/payroll" => "business-and-industry/employing-people",
        "/browse/employing-people/pensions" => "",
        "/browse/employing-people/recruiting-hiring" => "business-and-industry/employing-people",
        "/browse/employing-people/time-off" => "",
        "/browse/employing-people/trade-unions" => "",

        # Environment and countryside

        # Housing and local services


        # Money and tax
        "/browse/tax" => "money",
        "/browse/tax/capital-gains" => "money/personal-tax",
        "/browse/tax/court-claims-debt-bankruptcy" =>  "money/court-claims-debt-bankruptcy",
        "/browse/tax/dealing-with-hmrc" =>  "money/dealing-with-hmrc",
        "/browse/tax/income-tax" =>  "money/income-tax" ,
        "/browse/tax/inheritance-tax" =>  "money/personal-tax-inheritance-tax",
        "/browse/tax/national-insurance" =>  "money/national-insurance",
        "/browse/tax/self-assessment" =>  "money/self-assessment",
        "/browse/tax/vat" => "money/vat",


        # Passports, travel and living abroad
        "/browse/abroad" => "going-and-being-abroad",
        "/browse/abroad/living-abroad" => "going-and-being-abroad/living-abroad",
        "/browse/abroad/passports" => "going-and-being-abroad/passports",
        "/browse/abroad/travel-abroad" => "going-and-being-abroad/travel-abroad",


        # Visas and immigration
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

        # Working, jobs and pensions
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
        "/topic/business-tax/vat" => "money/vat",

        # Climate change and energy
        "/topic/climate-change-energy" => "environment/climate-change-energy",
        "/topic/climate-change-energy/climate-change-agreements" => "environment/climate-change-adaptation",
        "/topic/climate-change-energy/emissions" => "environment/climate-change-energy-emissions",
        "/topic/climate-change-energy/energy-efficiency" => "environment/climate-change-energy-energy-efficiency",
        "/topic/climate-change-energy/energy-infrastructure" => "environment/energy-infrastructure",
        "/topic/climate-change-energy/energy-prices-bills" => "housing-local-and-community/household-energy",
        "/topic/climate-change-energy/energy-security" => "business/uk-energy-security",
        "/topic/climate-change-energy/international-climate-change" => "environment/climate-change-international-action",
        "/topic/climate-change-energy/low-carbon-energy" => "environment/low-carbon-technologies",

        # Coal

        # Commercial fishing and fisheries

        # Community organisations

        # Company registration and filing

        # Competition

        # Crime and policing

        # Dealing with HMRC
        "/topic/dealing-with-hmrc" => "money/dealing-with-hmrc",
        "/topic/dealing-with-hmrc/complaints-appeals" => "money/complaints-appeals",
        "/topic/dealing-with-hmrc/paying-hmrc" => "money/paying-hmrc",
        "/topic/dealing-with-hmrc/phishing-scams" => "money/phishing-scams",
        "/topic/dealing-with-hmrc/shared-workspace" => "money/shared-workspace",
        "/topic/dealing-with-hmrc/software-development" => "money/dealing-with-hmrc-software-development",
        "/topic/dealing-with-hmrc/tax-agent-guidance" => "money/tax-agent-guidance",
        "/topic/dealing-with-hmrc/tax-avoidance" => "money/tax-avoidance",
        "/topic/dealing-with-hmrc/tax-compliance" => "money/tax-compliance",

        # Death and wills

        # Defence and armed forces

        # Driving and motorcycle instructors

        # Driving tests and learning to drive

        # Environmental management

        # Farming and food grants and payments

        # Further education and skills

        # Government

        # Guidance for government digital publishing and services

        # Health protection

        # Help for British national overseas

        # High Speed 2

        # Higher education

        # Housing

        # Intellectual property

        # Keeping farmed animals

        # Land registration

        # Law and the justice system

        # Legal aid

        # Local communities

        # Local government

        # MOT and vehicle tests

        # Medicines, medical devices and blood regulation and safety

        # Oil and gas

        # Outdoor access and recreation

        # Personal tax
        "/topic/personal-tax" => "money/personal-tax",
        "/topic/personal-tax/capital-gains-tax" => "money/capital-gains-tax",
        "/topic/personal-tax/coming-to-uk" => "money/coming-to-uk",
        "/topic/personal-tax/foreign-entertainer-rules" => "money/foreign-entertainer-rules",
        "/topic/personal-tax/income-tax" => "money/income-tax",
        "/topic/personal-tax/inheritance-tax" => "money/personal-tax-inheritance-tax",
        "/topic/personal-tax/leaving-uk" => "money/leaving-uk",
        "/topic/personal-tax/living-working-abroad-offshore" => "money/living-working-abroad-offshore",
        "/topic/personal-tax/national-insurance" => "money/national-insurance",
        "/topic/personal-tax/non-resident-landlord-scheme" => "money/non-resident-landlord-scheme",
        "/topic/personal-tax/self-assessment" => "money/self-assessment",
        "/topic/personal-tax/savings-investment-tax" => "money/savings-investment-tax",
        "/topic/personal-tax/personal-tax/trusts" => "money/trusts",

        # Planning and development

        # Population screening programmes

        # Prisons and probation

        # Producing and distributing food

        # Public safety and emergencies

        # Schools, colleges and children's services

        # Setting up and running a charity

        # Ships and cargoes

        # Transport

        # Visas and immigration operational guidance
        "/topic/immigration-operational-guidance" => "",
        "/topic/immigration-operational-guidance/asylum-policy" => "",
        "/topic/immigration-operational-guidance/commercial-casework-guidance" => "",
        "/topic/immigration-operational-guidance/enforcement" => "",
        "/topic/immigration-operational-guidance/entry-clearance-guidance" => "entering-staying-uk/visas-entry-clearance",
        "/topic/immigration-operational-guidance/fees-forms" => "",
        "/topic/immigration-operational-guidance/immigration-rules" => "entering-staying-uk/immigration-rules",
        "/topic/immigration-operational-guidance/modernised-guidance" => "",
        "/topic/immigration-operational-guidance/nationality-guidance" => "",
        "/topic/immigration-operational-guidance/non-compliance-biometric-registration" => "",
        "/topic/immigration-operational-guidance/rights-responsibilities" => "",
        "/topic/immigration-operational-guidance/stateless-guidance" => "",
        "/topic/immigration-operational-guidance/visitors" => "entering-staying-uk/visit-and-transit-visas",
        "/topic/immigration-operational-guidance/windrush-scheme" => "",

        # Work and careers
        "/topic/work-careers" => "",
        "/topic/work-careers/government-graduate-schemes" => "",
        "/topic/work-careers/public-service-pensions" => "employment/public-service-pensions",
        "/topic/work-careers/secondments-with-government" => "employment/secondments-with-government",
        "/topic/work-careers/trade-unions" => "",

        # Working at sea


      }
  end
end
