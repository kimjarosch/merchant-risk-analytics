-- 03_create_merchant_features.sql
-- Creates merchant-level features for onboarding risk scorecard
-- Run after Step 2 data generation is loaded into SQLite


DROP TABLE IF EXISTS merchant_features;

CREATE TABLE merchant_features AS
WITH
-- approved transactions only (core "performance" base)
approved_txns AS (
  SELECT
    t.txn_id,
    t.merchant_id,
    date(t.txn_ts) AS txn_date,
    t.amount,
    t.payment_method,
    t.device_id,
    t.ip_address
  FROM transactions t
  WHERE t.status = 'approved'
),

-- all transactions (to calculate approval rate)
all_txns AS (
  SELECT
    merchant_id,
    COUNT(*) AS txn_total,
    SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) AS txn_approved,
    SUM(CASE WHEN status = 'declined' THEN 1 ELSE 0 END) AS txn_declined
  FROM transactions
  GROUP BY merchant_id
),

-- refunded amounts and counts
refunds_by_merchant AS (
  SELECT
    a.merchant_id,
    COUNT(*) AS refund_count,
    SUM(r.refund_amount) AS refund_amount
  FROM refunds r
  JOIN approved_txns a ON r.txn_id = a.txn_id
  GROUP BY a.merchant_id
),

-- dispute amounts and counts
disputes_by_merchant AS (
  SELECT
    a.merchant_id,
    COUNT(*) AS dispute_count,
    SUM(d.dispute_amount) AS dispute_amount,
    SUM(CASE WHEN d.outcome = 'lost' THEN 1 ELSE 0 END) AS dispute_lost_count
  FROM disputes d
  JOIN approved_txns a ON d.txn_id = a.txn_id
  GROUP BY a.merchant_id
),

-- distinct device/ip reuse (simple fraud signal)
device_ip_signals AS (
  SELECT
    merchant_id,
    COUNT(DISTINCT device_id) AS distinct_devices,
    COUNT(DISTINCT ip_address) AS distinct_ips
  FROM approved_txns
  GROUP BY merchant_id
),

-- transaction stats
txn_stats AS (
  SELECT
    merchant_id,
    COUNT(*) AS approved_txn_count,
    AVG(amount) AS avg_amount,
    SUM(amount) AS gmv,
    MAX(amount) AS max_amount
  FROM approved_txns
  GROUP BY merchant_id
),

-- time window: how many active days
active_days AS (
  SELECT
    merchant_id,
    COUNT(DISTINCT txn_date) AS active_days
  FROM approved_txns
  GROUP BY merchant_id
)

SELECT
  m.merchant_id,
  m.merchant_name,
  m.industry,
  m.country,
  m.onboard_date,
  m.onboarding_channel,

  -- volume + approval behavior
  COALESCE(at.txn_total, 0) AS txn_total,
  COALESCE(at.txn_approved, 0) AS txn_approved,
  COALESCE(at.txn_declined, 0) AS txn_declined,
  CASE
    WHEN COALESCE(at.txn_total, 0) = 0 THEN NULL
    ELSE ROUND(1.0 * at.txn_approved / at.txn_total, 4)
  END AS approval_rate,

  -- approved txn stats
  COALESCE(ts.approved_txn_count, 0) AS approved_txn_count,
  ROUND(COALESCE(ts.avg_amount, 0), 2) AS avg_amount,
  ROUND(COALESCE(ts.gmv, 0), 2) AS gmv,
  ROUND(COALESCE(ts.max_amount, 0), 2) AS max_amount,

  -- refunds/disputes
  COALESCE(rm.refund_count, 0) AS refund_count,
  ROUND(COALESCE(rm.refund_amount, 0), 2) AS refund_amount,
  CASE
    WHEN COALESCE(ts.approved_txn_count, 0) = 0 THEN NULL
    ELSE ROUND(1.0 * COALESCE(rm.refund_count, 0) / ts.approved_txn_count, 4)
  END AS refund_rate,

  COALESCE(dm.dispute_count, 0) AS dispute_count,
  ROUND(COALESCE(dm.dispute_amount, 0), 2) AS dispute_amount,
  COALESCE(dm.dispute_lost_count, 0) AS dispute_lost_count,
  CASE
    WHEN COALESCE(ts.approved_txn_count, 0) = 0 THEN NULL
    ELSE ROUND(1.0 * COALESCE(dm.dispute_count, 0) / ts.approved_txn_count, 4)
  END AS dispute_rate,

  -- simple fraud signals
  COALESCE(ds.distinct_devices, 0) AS distinct_devices,
  COALESCE(ds.distinct_ips, 0) AS distinct_ips,
  CASE
    WHEN COALESCE(ts.approved_txn_count, 0) = 0 THEN NULL
    ELSE ROUND(1.0 * ts.approved_txn_count / ds.distinct_devices, 3)
  END AS txns_per_device,
  CASE
    WHEN COALESCE(ts.approved_txn_count, 0) = 0 THEN NULL
    ELSE ROUND(1.0 * ts.approved_txn_count / ds.distinct_ips, 3)
  END AS txns_per_ip,

  -- activity
  COALESCE(ad.active_days, 0) AS active_days,
  CASE
    WHEN COALESCE(ad.active_days, 0) = 0 THEN NULL
    ELSE ROUND(1.0 * COALESCE(ts.approved_txn_count, 0) / ad.active_days, 2)
  END AS avg_approved_txns_per_day

FROM merchants m
LEFT JOIN all_txns at ON m.merchant_id = at.merchant_id
LEFT JOIN txn_stats ts ON m.merchant_id = ts.merchant_id
LEFT JOIN refunds_by_merchant rm ON m.merchant_id = rm.merchant_id
LEFT JOIN disputes_by_merchant dm ON m.merchant_id = dm.merchant_id
LEFT JOIN device_ip_signals ds ON m.merchant_id = ds.merchant_id
LEFT JOIN active_days ad ON m.merchant_id = ad.merchant_id;


-- validation query 
SELECT
  COUNT(*) AS merchants_in_feature_table,
  AVG(approval_rate) AS avg_approval_rate,
  AVG(refund_rate) AS avg_refund_rate,
  AVG(dispute_rate) AS avg_dispute_rate
FROM merchant_features;


--peek at data 
SELECT *
FROM merchant_features
ORDER BY dispute_rate DESC
LIMIT 10;
