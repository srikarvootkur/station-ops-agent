# Phase 0 — Requirements & Architecture

### Goal of Phase 0
Build an **AI-assisted operations helper** that saves time every day by automating:
- Price decision suggestions for fuel
- Drafting vendor orders
- Sending a morning summary report

I can run this remotely and start with a few stations.

### Time Estimate for Phase 0 MVP
**8–12 weeks**

---

## What Exactly Will Phase 0 Do?

### 1) Fuel Pricing Agent (Version 0)
- Calculates suggested price changes based on DTW cost, competitor prices, and required margin.
- Sends daily price suggestions through Slack.
- User just clicks **Approve** (1-click).

### 2) Vendor Ordering Agent (Version 0)
- Predicts when SKUs need to be reordered based on past sales + safety stock.
- Builds CSV + draft email to vendor.
- Manager reviews and clicks **Approve** to send.

### 3) Daily Operations Brief (Slack Message)
Every morning at 7:30 AM local time:
- Today’s fuel price suggestions
- Inventory low-risk alerts
- Fuel days-to-empty estimate

---

## Data Needed (inputs)
- POS exports (hourly gallons + daily item sales)
- DTW wholesale fuel cost + fees per grade
- Competitor fuel prices
- Vendor + SKU data (vendor, case sizes, lead times, etc)

---

## How Inventory Will Be Estimated (Phase 0)

In Phase 0 we won’t require manual physical counting every day.  
Instead we will create a **perpetual inventory estimate** based on movement.

Baseline formula:

`on_hand_today = on_hand_yesterday + deliveries - sales - adjustments`

Where:
- **deliveries** = cases * case_size (from vendor invoices or delivery confirmation)
- **sales** = daily POS scan data
- **adjustments** = manual corrections (breakage, returns, theft suspicions, etc)

This gives us a continuous, estimated real-time on-hand quantity without requiring full daily counts.

Over time:
- If shrink trends show certain SKUs drift negative (energy drinks, cigarettes, vapes), then we flag them.
- Once a month (or week), manager can perform a small targeted cycle count on the top A-items and we correct the baseline.  
  (This keeps accuracy high without heavy labor.)

This approach lets us do reorder logic and safety stock calculations **immediately** while still being realistic operationally — without requiring perfect inventory tracking from day one.



## What AI Does vs What It Does NOT Do

| AI does | AI does NOT do |
|---------|----------------|
| Writes draft vendor emails | Does not compute fuel price math |
| Routes which tool to run | Does not set margins |
| Explains reasoning in natural English | Does not break guardrails |
| Suggests actions | Does not auto-apply without approval |

All sensitive business rules, math and limits stay in Python (deterministic and safe).

---

## AWS Architecture (Phase 0)

- Compute: ECS Fargate (main agent backend) + Lambda (scheduled jobs)
- DB: Postgres (state + audit log)
- Storage: S3 (POS CSVs + generated vendor CSVs)
- Schedules: EventBridge Cron (ex: hourly for pricing)
- Email: Amazon SES (send vendor emails)
- Approvals UI: Slack App + buttons
- Security: Secrets Manager, IAM least privilege, VPC private networking

---

## Services / Jobs in Phase 0
- POS ingest → load CSV to Postgres
- Pricing Job (hourly)
- Vendor Reorder Job (weekly)
- Daily Ops Brief (7:30 AM)
- FastAPI endpoints for:  
  `/approve_price`  
  `/send_vendor_email`  
  `/list_proposals`

---

## Simple Explanation

This first phase will NOT automatically change prices or automatically order cases.  
It will **calculate everything for him** and send him the best recommended action.  
He only needs to click *Approve*.

**Outcome for Phase 0:**
- Saves 1–2 hours per day across pricing + orders
- Reduces mistakes
- Makes decisions consistent and data-driven
- Gives us measurable ROI numbers to show other gas station owners later

---

## Mermaid Architecture Diagram

```mermaid
graph TD
  subgraph Client_Approvals
    SLK[Slack App Buttons_Approvals]
    CON[Small Web Console]
  end

  subgraph AWS_VPC
    API[FastAPI Agent Orchestrator ECS]
    LPR[Lambda Jobs Ingest_Pricing_Brief]
    RDS[Postgres]
    S3[S3 Storage]
    SES[SES Email]
    EVT[EventBridge Cron]
    BR[Bedrock LLM Endpoint]
  end

  subgraph External
    POS[POS Back Office CSV]
    DTW[DTW Wholesale Costs]
    COMP[Competitor Price Feed]
  end

  POS -->|Upload| S3
  DTW -->|Upload| S3
  COMP -->|Poll| API

  S3 -->|Trigger| LPR
  EVT --> LPR
  EVT --> API

  LPR -->|Insert| RDS
  API -->|Read_Write| RDS
  API -->|Read_Write| S3

  API -->|Draft Emails_Plan| BR
  API -->|Send Emails| SES

  SLK -->|Approval Button| API
  API -->|Post Results| SLK

  CON -->|HTTPS| API
  ```
