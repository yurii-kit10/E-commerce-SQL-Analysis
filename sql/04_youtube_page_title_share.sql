WITH
  page_title_event AS (
    SELECT
      sp.continent,
      COUNT(
        CASE
          WHEN
            params.key = 'page_title'
            AND params.value.string_value LIKE '%YouTube%'
            THEN 1
          END) AS youtube_count,
      COUNT(
        CASE
          WHEN
            params.key = 'page_title'
            AND params.value.string_value IS NOT NULL
            THEN 1
          END) AS total_count
    FROM
      DA.event_params ep,
      UNNEST(event_params) AS params
    LEFT JOIN
      DA.session_params sp
      ON
        ep.ga_session_id = sp.ga_session_id
    WHERE
      params.key = 'page_title'
    GROUP BY
      sp.continent
  )
SELECT
  continent,
  youtube_count / total_count * 100 AS youtube_percent
FROM
  page_title_event
