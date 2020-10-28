# README

## Data sources

# Mainstream pages (/browse):

- `document_type: "mainstream_browse_page"`
- Top level URL: https://www.gov.uk/browse
- Top level API: https://www.gov.uk/api/content/browse
- Example page: https://www.gov.uk/browse/benefits/universal-credit
- corresponding API URL: https://www.gov.uk/api/content/browse/benefits/universal-credit


First level mainstream pages are linked to from the home page's list of topics (Benefits, Money and tax, etc)

# Specialist topic pages:

- `document_type: "topic"`
- Top level URL: https://www.gov.uk/topic
- Top level API: https://www.gov.uk/api/content/topic
- Example page: https://www.gov.uk/api/topic/transport
- corresponding API URL: https://www.gov.uk/api/content/topic/transport


# Taxons

- `document_type: "taxon"`
- Top-level URL (root): /* (with exceptions)
- Top-level API: https://www.gov.uk/api/content
- example page: https://www.gov.uk/welfare
- corresponding API URL: https://www.gov.uk/api/content/welfare


## Prototype:

- Currently handles mainstream pages: `/browse/<slug>` (and `/browse/<slug1></slug2>`)

for each of those pages, the prototype fetches `/browse/<slug>` from the prototype API,
which itself fetches:
- https://www.gov.uk/api/content/browse/<slug>
- taxon-search-filter (query string params from looking up taxon from slug)
- latest_news: https://www.gov.uk/api/search.json?...level_one_taxon=[uuid of taxon from slug]
- organisations: also coming from search.json with relevant taxon UUID
- featured_sections: same
- subtopic_sections: same
- related_topics: same


Question: does the search API only work with taxon UUIDs?
