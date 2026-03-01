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
- **High:** multiple risk signals triggered in the same week *or* a single extreme spike (e.g., sharp dispute/refund spike or steep approval-rate drop vs baseline).  
- **Medium:** one moderate signal triggered (e.g., dispute/refund spike **or** approval-rate drop vs baseline), monitored for escalation.

## Key Metrics Monitored
- **Approval rate** (drop vs baseline)
- **Dispute rate** (spike vs baseline)
- **Refund rate** (spike vs baseline)

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
