module Taxonomies

  TAXON = Hash[

    # Level 1
    "welfare" => "dded88e2-f92e-424f-b73e-6ad24a839c51",
    "business_and_industry" => "495afdb6-47be-4df1-8b38-91c8adb1eefc",
    "transport" => "a4038b29-b332-4f13-98b1-1c9709e216bc",
    "money" => "6acc9db4-780e-4a46-92b4-1812e3c2c48a",
    "entering_staying_uk" => "ba3a9702-da22-487f-86c1-8334a730e559",
    "work" => "d0f1e5a3-c8f4-4780-8678-994f19104b21",
    "defence_and_armed_forces" => "e491505c-77ae-45b2-84be-8c94b94f6a2b",
    "childcare_parenting" => "206b7f3a-49b5-476f-af0f-fd27e2a68473",
    "environment" => "3cf97f69-84de-41ae-bc7b-7e2cc238fa58",
    "going_and_being_abroad" => "9597c30a-605a-4e36-8bc1-47e5cdae41b3",

    # Level 2
    "personal_tax" => "a5c88a77-03ba-4100-bd33-7ee2ce602dc8",
    "business_tax" => "28262ae3-599c-4259-ae30-3c83a5ec02a1",
    "rights_foreign_nationals_uk" => "6e85c12f-f52b-41b3-93ad-59e5f19d64f6",
    "visas_entry_clearance" => "29480b00-dc4d-49a0-b48c-25dda8569325",
    "refugees_asylum_human_rights" => "08a8a69f-2825-4fe2-a4cf-c83458a5629e",
    "working" => "092348a4-b896-4f8f-a0dc-e6d4605a4904",
    "running_a_business" => "8aa41155-58ff-4d7d-a11a-7e3ef42863dd",
    "importing_exporting" => "c9dedc39-8eff-4e75-ac40-bd578e312763",
    "business_regulation" => "33bc0eed-62c7-4b0b-9a93-626c9e10c025",
    "childcare_and_early_years" => "f1d9c348-5c5e-4fc6-9172-13a62537d3ae",
    "food_and_farming" => "52ff5c99-a17b-42c4-a9d7-2cc92cccca39",
    "waste_and_recycling" => "f4e9e92d-9192-4e17-90c6-553339bc04c3",
    "science_and_innovation" => "ccb77bcc-56b4-419a-b5ce-f7c2234e0546",
    "passports" => "27b9c5cd-b390-4332-89be-73491df35a41",
    "living_abroad" => "d956c72a-246d-4787-af39-00bf58b2ea66",
    "travel_abroad" => "d96e4efc-9c26-4d9b-9fa7-a036b5c11a65",
    "benefits_entitlement" => "536f83c0-8c67-47a3-88a4-d5b1eda591ed",
    "universal_credit" => "62fcbba5-3a75-4d15-85a6-d8a80b03d57c",
    "tax_credits" => "a7f3005b-a3cd-4060-a127-725accb54f2e",
    "jobseekers_allowance" => "2a1bd1b1-5025-4313-9e5b-8352dd46f1d6",
    "carers_and_disability_benefits" => "05a9527b-e6e9-4a68-8dd7-7d84e6a24eef",
    "child_benefit" => "7a1ba896-b85a-4137-81d9-ab05b7ce67dd",
    "benefits_for_families" => "29dbee2a-5865-489b-860f-7eef54a5165a",
    "heating_and_housing_benefits" => "6c4c443c-2e11-4d25-aa93-2e3a38d9499c",
    "death_and_benefits" => "ac7b8472-5d09-4679-9551-87847b0ac827",

    # Level 3
    "capital_gains" => "43446591-3f95-443d-9fb2-56761a93106b"

  ]

  TAXON2 =
    {
      # Benefits
      "benefits" => Taxonomies::TAXON["welfare"],
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

      "tax" => Taxonomies::TAXON["money"],
      "capital-gains" => Taxonomies::TAXON["capital-gains"],
      "court-claims-debt-bankruptcy" => "7c4cf197-2dba-4a82-83e2-6c8bb332525c",
      "dealing-with-hmrc" => "b20215a9-25fb-4fa6-80a3-42e23f5352c2",
      "income-tax" => "104ee859-8278-406b-80cb-5727373e0198",
      "inheritance-tax" => "a5c88a77-03ba-4100-bd33-7ee2ce602dc8",
      "national-insurance" => "cc195f93-4244-489a-97e9-22480113c770",
      "self-assessment" => "24e91c04-21cb-479a-8f23-df0eaab31788",
      "vat" => "e04c9a5c-88e8-46e5-91d9-add405e098fb",

      # Visas and immigration

      "visas-immigration" => Taxonomies::TAXON["entering_staying_uk"],
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

      "working" => Taxonomies::TAXON["working"],
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

      "business" => Taxonomies::TAXON["Business and industry"],
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
      "maritime" => "4a9ab4d7-0d03-4c61-9e16-47787cbf53cd",

      # Passports, travel and living abroad
      "abroad" => Taxonomies::TAXON["going_and_being_abroad"],
      "passports" => Taxonomies::TAXON["passports"],
      "living-abroad" => Taxonomies::TAXON["living_abroad"],
      "travel-abroad" => Taxonomies::TAXON["travel_abroad"],
    }



  def Taxonomies.taxon_lookup(topic)
    Taxonomies::TAXON[topic]
  end

  def Taxonomies.taxon_filter_lookup(topic)
    Taxonomies::TAXON2[topic]
  end

end
