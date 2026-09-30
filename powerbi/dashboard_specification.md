# Final Power BI Build Specification

This specification is for the populated PostgreSQL database `ecommerce_intelligence` at `localhost:5433`. It is intentionally based on certified `analytics` views, not raw Olist tables.

## 1. Import only these PostgreSQL views

Import in **Import** mode and rename as shown.

| Power BI table | PostgreSQL view | Grain | Purpose |
| --- | --- | --- | --- |
| Fact Order | `analytics.order_financials` | one row per order | Executive sales, order, delivery KPIs |
| Fact Order Line | `analytics.order_line` | one row per order item | Products, categories, sellers, item/freight revenue |
| Fact Payment | `analytics.payment_detail` | one row per payment sequence | Payment methods, installments, payment value |
| Fact Review | `analytics.review_detail` | one row per review row | Review distribution and delivery/satisfaction relationship |
| Customer RFM | `analytics.customer_rfm` | one row per unique customer | RFM segments and customer value |
| Cohort Retention | `analytics.cohort_retention` | cohort month × purchase month | Retention matrix |
| Category Experience | `analytics.category_experience` | one row per category | Certified category revenue, delivery, review metrics |
| Seller Experience | `analytics.seller_experience` | one row per seller | Certified seller revenue, delivery, review metrics |

## 2. Do **not** import these objects

- Do not import any `raw.*` table. They duplicate the facts above or have incompatible grain. In particular, joining `raw.order_items`, `raw.order_payments`, and `raw.order_reviews` to an order table creates fan-out and overstates revenue.
- Do not import `analytics.delivery_experience`; it is a presentation extension of `analytics.order_financials` and duplicates all order-level measures.
- Do not relate any two fact tables directly. Do not enable bidirectional relationships.
- Do not use the generated Python CSVs as model tables. They are auditable snapshots/exports of the same database analytics; importing them would duplicate data. Use their PNGs only as optional documentation or compare their CSV values with the report during QA.

## 3. Power Query preparation and dimensions

Keep the eight imported facts as connection-only source queries, then create these reference queries in Power Query. Disable load for source queries only if using the resulting fact reference; otherwise retain the imported tables with the names above.

1. In Fact Order, Fact Order Line, Fact Payment, and Fact Review, add `Purchase Date = Date.From([order_purchase_timestamp])` and set type to Date.
2. Create `Dim Customer` from Fact Order: retain `customer_unique_id`; remove duplicates. Key: `customer_unique_id`.
3. Create `Dim Customer State` from Fact Order: retain `customer_state`; remove nulls and duplicates. Key: `customer_state`.
4. Create `Dim Category` from Fact Order Line: retain `category_name`; remove duplicates. Key: `category_name`.
5. Create `Dim Seller` from Fact Order Line: retain `seller_id`, `seller_state`; remove duplicates by `seller_id`. Key: `seller_id`.
6. Add this calculated column to Fact Order:

```DAX
Delivery Status =
SWITCH(
    TRUE(),
    ISBLANK('Fact Order'[delivery_days]), "Not delivered",
    'Fact Order'[is_late_delivery] = 1, "Late",
    "On time / early"
)
```

## 4. Relationships and cardinalities

Create only these active, single-direction, one-to-many relationships. Filters flow from the `Dim` table to the fact/aggregate table.

| From (1) | To (*) | Key |
| --- | --- | --- |
| Dim Date | Fact Order | `Date` → `Purchase Date` |
| Dim Date | Fact Order Line | `Date` → `Purchase Date` |
| Dim Date | Fact Payment | `Date` → `Purchase Date` |
| Dim Date | Fact Review | `Date` → `Purchase Date` |
| Dim Customer | Fact Order | `customer_unique_id` |
| Dim Customer | Fact Order Line | `customer_unique_id` |
| Dim Customer | Fact Payment | `customer_unique_id` |
| Dim Customer | Fact Review | `customer_unique_id` |
| Dim Customer | Customer RFM | `customer_unique_id` |
| Dim Customer State | Fact Order | `customer_state` |
| Dim Customer State | Fact Order Line | `customer_state` |
| Dim Customer State | Fact Payment | `customer_state` |
| Dim Customer State | Fact Review | `customer_state` |
| Dim Category | Fact Order Line | `category_name` |
| Dim Category | Category Experience | `category_name` |
| Dim Seller | Fact Order Line | `seller_id` |
| Dim Seller | Seller Experience | `seller_id` |

Leave `Cohort Retention` disconnected. Its dates mean cohort/purchase periods, not transactional calendar dates. Do not relate `Category Experience` or `Seller Experience` to Dim Date: they are full-dataset aggregate snapshots. Do not place a Dim Date slicer on visuals sourced from them.

## 5. Date table

Create this DAX table, then **Mark as date table** using `[Date]`.

```DAX
Dim Date =
ADDCOLUMNS(
    CALENDAR(DATE(2016, 1, 1), DATE(2018, 12, 31)),
    "Year", YEAR([Date]),
    "Quarter", "Q" & FORMAT([Date], "Q"),
    "Month Number", MONTH([Date]),
    "Month", FORMAT([Date], "MMM"),
    "Year Month", FORMAT([Date], "YYYY-MM"),
    "Year Month Sort", YEAR([Date]) * 100 + MONTH([Date])
)
```

Sort `Dim Date[Month]` by `Month Number` and `Year Month` by `Year Month Sort`. Use `Year Month` on monthly chart axes.

## 6. DAX measures

Create the following measures in the specified tables. Never substitute a line-level measure for an order-level measure.

### Fact Order — executive metrics

```DAX
All Orders = COUNTROWS('Fact Order')

Delivered Orders =
CALCULATE([All Orders], 'Fact Order'[order_status] = "delivered")

Delivered Revenue =
CALCULATE(SUM('Fact Order'[item_revenue]), 'Fact Order'[order_status] = "delivered")

Delivered Freight Revenue =
CALCULATE(SUM('Fact Order'[freight_revenue]), 'Fact Order'[order_status] = "delivered")

Delivered GMV =
CALCULATE(SUM('Fact Order'[gross_merchandise_value]), 'Fact Order'[order_status] = "delivered")

Delivered Customers =
CALCULATE(
    DISTINCTCOUNT('Fact Order'[customer_unique_id]),
    'Fact Order'[order_status] = "delivered"
)

Average Order Value = DIVIDE([Delivered Revenue], [Delivered Orders])

Average Revenue per Customer = DIVIDE([Delivered Revenue], [Delivered Customers])

Average Delivery Days =
CALCULATE(
    AVERAGE('Fact Order'[delivery_days]),
    'Fact Order'[order_status] = "delivered",
    NOT ISBLANK('Fact Order'[delivery_days])
)

Late Deliveries =
CALCULATE(
    COUNTROWS('Fact Order'),
    'Fact Order'[order_status] = "delivered",
    NOT ISBLANK('Fact Order'[delivery_days]),
    'Fact Order'[is_late_delivery] = 1
)

Delivered With Actual Date =
CALCULATE(
    COUNTROWS('Fact Order'),
    'Fact Order'[order_status] = "delivered",
    NOT ISBLANK('Fact Order'[delivery_days])
)

Late Delivery Rate = DIVIDE([Late Deliveries], [Delivered With Actual Date])

Revenue MoM % =
VAR PreviousMonthRevenue = CALCULATE([Delivered Revenue], DATEADD('Dim Date'[Date], -1, MONTH))
RETURN DIVIDE([Delivered Revenue] - PreviousMonthRevenue, PreviousMonthRevenue)

Order MoM % =
VAR PreviousMonthOrders = CALCULATE([Delivered Orders], DATEADD('Dim Date'[Date], -1, MONTH))
RETURN DIVIDE([Delivered Orders] - PreviousMonthOrders, PreviousMonthOrders)
```

### Fact Order Line — product/category detail

```DAX
Delivered Item Revenue (Line) =
CALCULATE(SUM('Fact Order Line'[price]), 'Fact Order Line'[order_status] = "delivered")

Delivered Freight (Line) =
CALCULATE(SUM('Fact Order Line'[freight_value]), 'Fact Order Line'[order_status] = "delivered")

Delivered Line GMV = [Delivered Item Revenue (Line)] + [Delivered Freight (Line)]

Delivered Orders (Line) =
CALCULATE(DISTINCTCOUNT('Fact Order Line'[order_id]), 'Fact Order Line'[order_status] = "delivered")

Product Rank by Revenue =
RANKX(ALL('Fact Order Line'[product_id]), [Delivered Item Revenue (Line)], , DESC, DENSE)
```

### Fact Payment — payment metrics

```DAX
Delivered Payment Value =
CALCULATE(SUM('Fact Payment'[payment_value]), 'Fact Payment'[order_status] = "delivered")

Payment Records = COUNTROWS('Fact Payment')

Average Payment Installments = AVERAGE('Fact Payment'[payment_installments])

Payment Value Share =
DIVIDE(
    [Delivered Payment Value],
    CALCULATE([Delivered Payment Value], REMOVEFILTERS('Fact Payment'[payment_type]))
)
```

### Fact Review — review metrics

```DAX
Review Count = COUNTROWS('Fact Review')

Average Review Score = AVERAGE('Fact Review'[review_score])

Low Review Count = CALCULATE([Review Count], 'Fact Review'[review_score] <= 2)

Low Review Rate = DIVIDE([Low Review Count], [Review Count])
```

### Customer RFM and cohort metrics

```DAX
RFM Customers = DISTINCTCOUNT('Customer RFM'[customer_unique_id])

RFM Revenue = SUM('Customer RFM'[monetary])

Repeat Customers = CALCULATE([RFM Customers], 'Customer RFM'[frequency] > 1)

Repeat Customer Rate = DIVIDE([Repeat Customers], [RFM Customers])

Retained Customers = SUM('Cohort Retention'[retained_customers])

Cohort Size =
CALCULATE(
    MAX('Cohort Retention'[retained_customers]),
    ALLEXCEPT('Cohort Retention', 'Cohort Retention'[cohort_month]),
    'Cohort Retention'[cohort_index] = 0
)

Retention Rate = DIVIDE([Retained Customers], [Cohort Size])
```

### Certified category/seller aggregate metrics

```DAX
Category Revenue = SUM('Category Experience'[revenue])
Category Freight Revenue = SUM('Category Experience'[freight_revenue])
Category Delivered Orders = SUM('Category Experience'[delivered_orders])
Category Average Review Score = AVERAGE('Category Experience'[avg_review_score])
Category Late Delivery Rate = AVERAGE('Category Experience'[late_delivery_rate])

Seller Revenue = SUM('Seller Experience'[item_revenue])
Seller Delivered Orders = SUM('Seller Experience'[delivered_orders])
Seller Average Review Score = AVERAGE('Seller Experience'[avg_review_score])
Seller Late Delivery Rate = AVERAGE('Seller Experience'[late_delivery_rate])
```

## 7. KPI definitions and control totals

| KPI | Source/logic | Expected unfiltered result |
| --- | --- | --- |
| All Orders | Fact Order, one row per order | 99,441 |
| Delivered Orders | Fact Order filtered `delivered` | 96,478 |
| Delivered Revenue | Sum `item_revenue`, delivered only | R$13,221,498.11 |
| Delivered Freight Revenue | Sum `freight_revenue`, delivered only | R$2,198,275.64 |
| Delivered GMV | Item plus freight, delivered only | R$15,419,773.75 |
| Delivered Customers | Distinct `customer_unique_id`, delivered only | 93,358 |
| AOV | Delivered Revenue / Delivered Orders | R$137.04 |
| Average Review Score | Average Fact Review `review_score` | 4.09 |
| Late Delivery Rate | Late delivered orders / delivered orders with actual delivery date | 8.11% (7,826 / 96,470) |
| Delivered Payment Value | Fact Payment sum, delivered only | R$15,422,461.77 |
| Repeat Customer Rate | Customer RFM frequency > 1 / RFM customers | 2.91% (2,801 / 96,096) |

Payment value need not equal GMV: Olist contains payment adjustments and its payment fact is a different business measure. Do not use payment value as revenue.

## 8. Report pages and visuals

### Page 1 — Executive Overview

- **KPI cards:** Delivered Revenue, Delivered Orders, Delivered Customers, AOV, Average Review Score, Late Delivery Rate. Apply visual filter `order_status = delivered` only where the measure does not already do so; avoid redundant filters.
- **Line and clustered column chart:** axis Dim Date[Year Month]; columns Delivered Revenue; line Delivered Orders. Tooltip: AOV, Revenue MoM %, Order MoM %.
- **Bar chart:** axis Dim Category[category_name]; values Category Revenue; Top N 10 by Category Revenue. Tooltip: Category Delivered Orders, Category Average Review Score, Category Late Delivery Rate. No date slicer interaction.
- **Filled map:** location Dim Customer State[customer_state]; size Delivered Revenue; tooltip Delivered Orders, AOV, Late Delivery Rate.
- **Insight card:** Late Deliveries and Low Review Rate.

### Page 2 — Sales and Payment Performance

- **Line chart:** axis Dim Date[Year Month]; values Delivered Revenue and Delivered Freight Revenue.
- **Matrix:** rows Dim Category[category_name], values Delivered Item Revenue (Line), Delivered Freight (Line), Delivered Orders (Line); Top N 15 by revenue.
- **Table:** Fact Order Line[product_id], Dim Category[category_name], Delivered Item Revenue (Line), Delivered Orders (Line), Product Rank by Revenue; visual filter rank <= 20.
- **Donut chart:** legend Fact Payment[payment_type]; values Delivered Payment Value; tooltip Payment Value Share and Average Payment Installments.
- **Column chart:** axis Fact Payment[payment_installments]; values Delivered Payment Value; filter payment type is not `not_defined` if it creates an unusable category.

### Page 3 — Customer Intelligence

- **KPI cards:** RFM Customers, Repeat Customers, Repeat Customer Rate, RFM Revenue.
- **Bar chart:** axis Customer RFM[customer_segment]; values RFM Revenue; tooltip RFM Customers and average `monetary`.
- **Column chart:** axis customer_segment; values RFM Customers.
- **Scatter chart:** details customer_segment; X average `recency_days`; Y average `monetary`; size RFM Customers.
- **Table:** customer_unique_id, recency_days, frequency, monetary, rfm_score, customer_segment; Top N 100 by monetary. Enable drill-through to Customer Detail.

### Page 4 — Product, Category, and Seller Intelligence

- **Scatter chart:** details Dim Category[category_name]; X Category Late Delivery Rate; Y Category Average Review Score; size Category Revenue. Tooltip: Category Delivered Orders, Category Freight Revenue, `avg_delivery_days`. Do not use Date slicer.
- **Bar chart:** axis Dim Category[category_name]; values Category Revenue; Top N 15.
- **Table:** seller_id, seller_state, Seller Revenue, Seller Delivered Orders, Seller Average Review Score, Seller Late Delivery Rate; Top N 25 by Seller Revenue. Enable drill-through to Seller Detail.
- **Decomposition tree:** analyze Delivered Item Revenue (Line); explain by category_name then seller_state then seller_id.

### Page 5 — Retention and Cohorts

- **Matrix:** rows Cohort Retention[cohort_month]; columns cohort_index; values Retention Rate; conditional-format background colour. Tooltip: Retained Customers and Cohort Size.
- **Line chart:** axis cohort_index; values Retention Rate; legend cohort_month. Limit cohorts to a readable recent selection if required.
- **Table:** cohort_month, cohort_index, Retained Customers, Cohort Size, Retention Rate.
- Do not place transactional Date/Customer/Category slicers on this disconnected page.

### Page 6 — Delivery and Customer Experience

- **KPI cards:** Average Delivery Days, Late Delivery Rate, Average Review Score, Low Review Rate.
- **Clustered column chart:** axis Fact Order[Delivery Status]; values Average Review Score; tooltip count of orders and Average Delivery Days.
- **Bar chart:** axis Dim Customer State[customer_state]; values Average Delivery Days; tooltip Late Delivery Rate, Average Review Score.
- **Column chart:** axis Fact Review[review_score]; values Review Count; visual filter order status = delivered if comparing delivered review outcomes.
- **Scatter chart:** details Dim Seller[seller_id]; X Seller Late Delivery Rate; Y Seller Average Review Score; size Seller Revenue; filter Seller Delivered Orders >= 20. No Date slicer.

## 9. Slicers, filters, interactions, and drill-through

- **Report-level:** exclude no statuses globally; measures intentionally define delivered scope.
- **Pages 1, 2, 6:** Dim Date[Year]/[Year Month], Dim Customer State[customer_state].
- **Pages 2, 4:** Dim Category[category_name], Dim Seller[seller_state].
- **Page 3:** Customer RFM[customer_segment], frequency band (optional).
- **Disable Date and Customer State interactions** on Category Experience visuals; disable Date, Customer State, and Category interactions on Seller Experience visuals. These aggregates only respond safely to their respective Dim Category or Dim Seller filters because they are full-dataset snapshots.
- **Customer Detail drill-through:** field Dim Customer[customer_unique_id]; show Fact Order date/revenue/delivery-status table and Customer RFM segment card.
- **Seller Detail drill-through:** field Dim Seller[seller_id]; show Seller Experience cards plus Fact Order Line product/category table.
- Keep cross-filter direction visual-to-visual as default, but turn off interactions that mix transaction facts with disconnected cohort/aggregate visuals.

## 10. Analytical caveats to display

- Revenue is item price. Freight and GMV are separate explicitly named measures.
- Customer identity is `customer_unique_id`; `customer_id` is order-level and must not be used for customer KPIs.
- Payment value is not revenue and can differ from GMV.
- Reviews are at review-row grain; use Fact Review only for review counts/distributions/scores.
- Delivery duration excludes orders without an actual customer delivery date; eight delivered orders have no such date.
- RFM is a fixed snapshot using the dataset maximum purchase date; it is not responsive to a calendar slicer.
- Cohort, category experience, and seller experience are pre-aggregated full-dataset views. Do not apply transactional Date filters to them; category aggregates only respond to Dim Category and seller aggregates only respond to Dim Seller.
- The data is historical Olist marketplace data; delivery/review patterns are associations, not causal proof.

## 11. Exact build order

1. Run `database/analytics_views.sql` once so the eight certified views exist.
2. Connect Power BI to PostgreSQL and import the eight named views only.
3. Rename facts, add Purchase Date columns, create the five dimensions, and create Dim Date.
4. Create every relationship in Section 4; validate there are no fact-to-fact or bidirectional links.
5. Add the Delivery Status calculated column and all DAX measures.
6. Create Page 1 and validate every Section 7 control total before building any other page.
7. Build Pages 2–6 in order; apply the stated slicer and interaction restrictions.
8. Test Customer and Seller drill-through, Date slicers, category filters, and tooltips.
9. Compare a sample of visuals to the SQL scripts/Python exports, then save `powerbi/Ecommerce_Customer_Sales_Intelligence.pbix` and export screenshots to `powerbi/screenshots/`.
