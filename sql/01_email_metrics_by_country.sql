WITH
  -- Підрахунок кількості унікальних акаунтів за кожною комбінацією дати, країни, інтервалу надсилання, статусів підписки та верифікації
  account AS (
    SELECT
      s.date,
      sp.country,
      a.send_interval,
      a.is_verified,
      a.is_unsubscribed,
      COUNT(DISTINCT a.id) AS account_cnt
    FROM
      DA.account a
    JOIN
      DA.account_session acs
      ON
        a.id = acs.account_id
    JOIN
      DA.session s
      ON
        acs.ga_session_id = s.ga_session_id
    JOIN
      DA.session_params sp
      ON
        s.ga_session_id = sp.ga_session_id
    GROUP BY
      s.date,
      sp.country,
      a.send_interval,
      a.is_verified,
      a.is_unsubscribed
  ),
  -- Підрахунок статистики щодо надісланих, відкритих та відвіданих повідомлень
  email_metrics AS (
    SELECT
      DATE_ADD(s.date, INTERVAL es.sent_date DAY) AS sent_date,
      sp.country,
      a.send_interval,
      a.is_verified,
      a.is_unsubscribed,
      COUNT(DISTINCT es.id_message) AS sent_msg,
      COUNT(DISTINCT eo.id_message) AS open_msg,
      COUNT(DISTINCT ev.id_message) AS visit_msg
    FROM
      DA.account a
    JOIN
      DA.email_sent es
      ON
        a.id = es.id_account
    LEFT JOIN
      DA.email_open eo
      ON
        es.id_message = eo.id_message
    LEFT JOIN
      DA.email_visit ev
      ON
        es.id_message = ev.id_message
    JOIN
      DA.account_session acs
      ON
        a.id = acs.account_id
    JOIN
      DA.session s
      ON
        acs.ga_session_id = s.ga_session_id
    JOIN
      DA.session_params sp
      ON
        s.ga_session_id = sp.ga_session_id
    GROUP BY
      DATE_ADD(s.date, INTERVAL es.sent_date DAY),
      sp.country,
      a.send_interval,
      a.is_verified,
      a.is_unsubscribed
  ),
  -- Об'єднання даних про акаунти та метрики email для подальшого аналізу
  combined_data AS (
    SELECT
      acc.date,
      acc.country,
      acc.send_interval,
      acc.is_verified,
      acc.is_unsubscribed,
      acc.account_cnt,
      0 AS sent_msg,
      0 AS open_msg,
      0 AS visit_msg
    FROM
      account acc
    UNION ALL
    SELECT
      em.sent_date AS date,
      em.country,
      em.send_interval,
      em.is_verified,
      em.is_unsubscribed,
      0 AS account_cnt,
      em.sent_msg,
      em.open_msg,
      em.visit_msg
    FROM
      email_metrics em
  ),
  -- Обчислення загальних сум по кожній країні і надання рангу для обох метрик: акаунтів та надісланих повідомлень
  sums AS (
    SELECT
      *,
      DENSE_RANK()
        OVER (ORDER BY total_country_account_cnt DESC)
        AS rank_total_country_account_cnt,
      DENSE_RANK()
        OVER (ORDER BY total_country_sent_cnt DESC)
        AS rank_total_country_sent_cnt
    -- Обчислення сум по акаунтах і надісланих повідомленнях для кожної країни
    FROM
      (
        SELECT
          *,
          SUM(account_cnt)
            OVER (PARTITION BY country) AS total_country_account_cnt,
          SUM(sent_msg) OVER (PARTITION BY country) AS total_country_sent_cnt
        FROM
          combined_data
      ) AS final_groups
  )
-- Основний вибір даних для виведення результату
SELECT
  date,
  country,
  send_interval,
  is_verified,
  is_unsubscribed,
  account_cnt,
  sent_msg,
  open_msg,
  visit_msg,
  total_country_account_cnt,
  total_country_sent_cnt,
  rank_total_country_account_cnt,
  rank_total_country_sent_cnt
FROM
  sums
WHERE
  rank_total_country_account_cnt <= 10
  OR rank_total_country_sent_cnt <= 10
ORDER BY
  date,
  country
