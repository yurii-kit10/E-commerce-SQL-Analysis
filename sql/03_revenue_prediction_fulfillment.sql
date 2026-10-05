WITH
  date_revenue AS (
    SELECT
      s.date,
      SUM(p.price) OVER (ORDER BY s.date) AS revenue
    FROM
      `DA.order` o
    JOIN
      `DA.product` p
      ON
        o.item_id = p.item_id
    JOIN
      `DA.session` s
      ON
        o.ga_session_id = s.ga_session_id
  ),
  date_predict_revenue AS (
    SELECT
      rp.date,
      SUM(rp.predict) OVER (ORDER BY rp.date) AS predict_revenue
    FROM
      `DA.revenue_predict` rp
  )
SELECT DISTINCT
  dpr.date,
  dr.revenue / dpr.predict_revenue * 100 AS goal_percent
FROM
  date_revenue dr
JOIN
  date_predict_revenue dpr
  ON
    dr.date = dpr.date
