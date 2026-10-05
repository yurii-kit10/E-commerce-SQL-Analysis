WITH
  revenue_usd AS (
    SELECT
      sp.continent AS Continent,
      SUM(p.price) AS Revenue,
      SUM(
        CASE
          WHEN sp.device = 'mobile' THEN p.price
          END) AS Revenue_from_Mobile,
      SUM(
        CASE
          WHEN sp.device = 'desktop' THEN p.price
          END) AS Revenue_from_Desktop
    FROM
      `DA.order` o
    JOIN
      `DA.product` p
      ON
        o.item_id = p.item_id
    JOIN
      `DA.session_params` sp
      ON
        o.ga_session_id = sp.ga_session_id
    GROUP BY
      sp.continent
  ),
  count_account_session AS (
    SELECT
      sp.continent AS Continent,
      COUNT(acs.account_id) AS Account_Count,
      COUNT(CASE WHEN a.is_verified = 1 THEN a.id END) AS Verified_Account
    FROM
      `DA.account` a
    JOIN
      `DA.account_session` acs
      ON
        a.id = acs.account_id
    JOIN
      `DA.session_params` sp
      ON
        acs.ga_session_id = sp.ga_session_id
    GROUP BY
      sp.continent
  ),
  count_session AS (
    SELECT
      sp.continent,
      COUNT(sp.ga_session_id) AS Session_Count
    FROM
      `DA.session_params` sp
    GROUP BY
      sp.continent
  )
SELECT
  r.Continent,
  r.Revenue,
  r.Revenue_from_Mobile,
  Revenue_from_Desktop,
  r.Revenue / SUM(r.Revenue) OVER () * 100 AS PERCENT_Revenue_from_Total,
  cas.Account_Count,
  cas.Verified_Account,
  cs.Session_Count
FROM
  count_account_session cas
JOIN
  revenue_USD r
  ON
    cas.Continent = r.Continent
JOIN
  count_session cs
  ON
    cas.Continent = cs.continent
GROUP BY
  r.Continent,
  r.Revenue,
  r.Revenue_from_Mobile,
  Revenue_from_Desktop,
  cas.Account_Count,
  cas.Verified_Account,
  cs.Session_Count
