# Structure of JSON responses


## Mainstream topics ("https://www.gov.uk/api/content/browse/#{topic_slug}")

eg https://www.gov.uk/api/content/browse/benefits


    {
      title
      description
      details: {
        ordered_second_level_browse_pages: [
          "<uuid1>",
          "<uuid2>",
          "<uuid3>"
          ...
        ]
      },
      links: {
        second_level_browse_pages: [
          { title, api_path, api_url, etc },
          { title, api_path, api_url, etc },
          { title, api_path, api_url, etc }
        ]
      }
    }


## Mainstream subtopics

## Specialist topics

eg https://www.gov.uk/api/content/topic/benefits-credits





## Specialist subtopics

    {
      title
      description
      details: {
        -- no ordered_second_level_browse_pages
      }
      links: {
        -- no second_level_browse_pages
        children: [
          { title, api_path, etc},
          { title, api_path, etc}
        ]
      }
    }
