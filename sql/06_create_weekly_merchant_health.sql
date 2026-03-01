DROP TABLE IF EXISTS weekly_merchant_health;

CREATE TABLE weekly_merchant_health AS
WITH base AS (
  SELECT
    merchant_id,
    -- Week start (Monday) in SQLite:
    date(txn_ts, 'weekday 1', '-7 days') AS week_start,

    COUNT(*) AS txn_total,
    SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) AS txn_approved,
    SUM(CASE WHEN status='declined' THEN 1 ELSE 0 END) AS txn_declined,

    SUM(CASE WHEN status='approved' THEN amount ELSE 0 END) AS approved_gmv,
    AVG(CASE WHEN status='approved' THEN amount END) AS avg_approved_amount
  FROM transactions
  GROUP BY merchant_id, week_start
),
refunds_w AS (
  SELECT
    t.merchant_id,
    date(t.txn_ts, 'weekday 1', '-7 days') AS week_start,
    COUNT(*) AS refund_count,
    SUM(r.refund_amount) AS refund_amount
  FROM refunds r
  JOIN transactions t ON r.txn_id = t.txn_id
  GROUP BY t.merchant_id, week_start
),
disputes_w AS (
  SELECT
    t.merchant_id,
    date(t.txn_ts, 'weekday 1', '-7 days') AS week_start,
    COUNT(*) AS dispute_count,
    SUM(d.dispute_amount) AS dispute_amount,
    SUM(CASE WHEN d.outcome='lost' THEN 1 ELSE 0 END) AS dispute_lost_count
  FROM disputes d
  JOIN transactions t ON d.txn_id = t.txn_id
  GROUP BY t.merchant_id, week_start
)
SELECT
  b.merchant_id,
  b.week_start,

  b.txn_total,
  b.txn_approved,
  b.txn_declined,

  ROUND(1.0 * b.txn_approved / NULLIF(b.txn_total, 0), 4) AS approval_rate,
  ROUND(COALESCE(b.approved_gmv, 0), 2) AS approved_gmv,
  ROUND(COALESCE(b.avg_approved_amount, 0), 2) AS avg_approved_amount,

  COALESCE(rw.refund_count, 0) AS refund_count,
  ROUND(COALESCE(rw.refund_amount, 0), 2) AS refund_amount,
  ROUND(1.0 * COALESCE(rw.refund_count, 0) / NULLIF(b.txn_approved, 0), 4) AS refund_rate,

  COALESCE(dw.dispute_count, 0) AS dispute_count,
  ROUND(COALESCE(dw.dispute_amount, 0), 2) AS dispute_amount,
  COALESCE(dw.dispute_lost_count, 0) AS dispute_lost_count,
  ROUND(1.0 * COALESCE(dw.dispute_count, 0) / NULLIF(b.txn_approved, 0), 4) AS dispute_rate

FROM base b
LEFT JOIN refunds_w rw
  ON b.merchant_id = rw.merchant_id AND b.week_start = rw.week_start
LEFT JOIN disputes_w dw
  ON b.merchant_id = dw.merchant_id AND b.week_start = dw.week_start;

SELECT COUNT(*) AS rows
FROM weekly_merchant_health;

SELECT MIN(week_start) AS min_week, MAX(week_start) AS max_week
FROM weekly_merchant_health;

SELECT *
FROM weekly_merchant_health
ORDER BY dispute_rate DESC
LIMIT 10;

