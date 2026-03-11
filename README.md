# Merchant Risk Analytics (Simulated Buy Now, Pay Later / BNPL)

**Tools:** SQL (SQLite), Python (Jupyter), Tableau Public  
**Focus:** merchant onboarding decisions + weekly monitoring & alerts

**Why it matters:** This mirrors how a Merchant Risk team scales safe growth—**screening merchants at onboarding** and **catching emerging risk quickly** with a prioritized weekly queue (severity + reason codes).

## Tableau Public Dashboards
- **Onboarding Risk Scorecard (Approve / Review / Decline):** [Merchant Onboarding Dashboard](https://public.tableau.com/app/profile/kimberly.jarosch/viz/MerchantOnboardingRiskScorecardSimulatedData/MerchantOnboardingRiskScorecardApproveReviewDecline)
- **Monitoring & Alerts (Weekly):** [Merchant Monitoring Dashboard](https://public.tableau.com/app/profile/kimberly.jarosch/viz/merchant_monitoring_alerts_dashboard/MerchantMonitoringAlerts?publish=yes)

## Project Summary
This project simulates the merchant risk lifecycle end-to-end:

1) **Onboarding Scorecard**
- Assigns merchants to **approve / manual_review / decline** using risk signals
- Includes a review-style queue for manual decisioning

2) **Monitoring & Alerts (Weekly)**
- Detects weekly deterioration/spikes and generates an operational **triage queue**
- Assigns **severity (Medium/High)** and **reason codes** to explain why merchants were flagged

## Severity Logic (Queue Prioritization)
Only merchant-weeks with at least one alert are included in the queue.

- **High:** triggered if **either**  
  - a **dispute rate spike** is detected (`dispute_rate_spike`), **or**  
  - a **refund rate spike AND approval-rate drop** happen in the same week (`refund_rate_spike` + `approval_rate_drop`)
- **Medium:** any other alerted merchant-week (e.g., single refund spike, single approval drop, or GMV surge without the High conditions)

Reason codes shown in the queue: `dispute_rate_spike`, `refund_rate_spike`, `approval_rate_drop`, `gmv_surge`.

## Key Metrics Monitored
- **Approval rate** (drop vs baseline)
- **Dispute rate** (spike vs baseline)
- **Refund rate** (spike vs baseline)

## Sample Findings (Simulated Data)
Onboarding Scorecard — 500 merchants evaluated

- 76.2% were approved outright, 22.8% flagged for manual review, and 1% declined — a distribution that reflects a realistic BNPL portfolio where most merchants pass but a meaningful queue still requires human decisioning
- Declined merchants consistently scored high on two signals: low approval rates (below 70%) and elevated dispute rates (above 3%), suggesting these two features carry the most discriminatory weight in the scoring model
- The portfolio averaged an 84.3% approval rate, a 2.5% refund rate, and a 1.1% dispute rate — metrics that established the baselines used downstream for weekly monitoring
- Electronics and beauty generated the largest review queues by industry volume, while gaming, travel, and marketplace showed the highest proportion of manual review flags relative to their size

Monitoring & Alerts — 26 weeks of simulated activity across 13,422 merchant-weeks

- 4,064 alert instances were generated across the monitoring window, with approval rate drops being the most common signal (2,530 instances), followed by refund spikes (1,401) and dispute spikes (526)
- GMV surges were rare (21 instances), suggesting they function better as a secondary signal than a standalone trigger — a potential candidate for alert suppression tuning in a future version
- In the most recent week, 128 merchants were flagged, with 5 escalated to High severity — a manageable queue size that validates the triage logic for operational use
- High severity alerts were concentrated in electronics and beauty, pointing to those segments as candidates for tighter onboarding thresholds or more frequent review cycles

## Key Features
- Rule-based alerting with baseline comparisons (weekly monitoring)
- Severity tiers (Medium / High) for triage prioritization
- Queue view designed for operational workflows
- Filters by **country / industry / onboarding channel**

## Repo Contents
- `notebooks/` → data simulation + feature engineering + scoring/alert logic
- `sql/` → SQLite queries for rollups/monitoring
- `tableau/` → Tableau workbooks (.twbx)
- `screenshots/` → dashboard screenshots

> Note: the SQLite DB is excluded due to GitHub size limits. Data is simulated and reproducible from the notebooks.

## Screenshots
### Onboarding Risk Scorecard
![Onboarding Dashboard](screenshots/dashboard_merchant_onboard_score.png)

### Monitoring & Alerts
![Monitoring Dashboard](screenshots/dashboard_monitor.png)

## How to Reproduce Locally
1. Run the notebooks in `notebooks/` to generate simulated CSV outputs  
2. (Optional) Load CSVs into SQLite (DB Browser for SQLite) and run queries in `sql/`  
3. Open the Tableau workbooks in `tableau/` and connect to the generated CSV outputs

## What I’d Improve Next (Roadmap)
- Threshold tuning + alert suppression logic
- Model-based severity scoring (logistic regression as a v2)
- Monitoring for drift / stability
