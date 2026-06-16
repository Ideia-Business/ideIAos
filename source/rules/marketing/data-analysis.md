---
id: data-analysis
name: "Data Analysis & Interpretation"
whenToUse: |
  Creating agents that interpret metrics, extract insights, benchmark performance,
  or produce analytical reports.
  NOT for: data collection/research, content creation, strategic planning, quality review.
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

# Data Analysis & Interpretation — Best Practices

## Core Principles

1. **Insight over raw data.** Never present numbers without interpretation. Every metric, percentage, and data point must be accompanied by a plain-language business implication. Raw data is noise; interpreted data is intelligence. If you cannot explain what a number means for the business, do not include it in the report.

2. **Always contextualize.** No metric exists in a vacuum. Compare every data point against at least one of these baselines: previous period (week-over-week, month-over-month), industry benchmark for the relevant segment and size tier, internal target or OKR, or competitor performance. A number without context has no meaning.

3. **Confidence levels on every finding.** Tag every insight and recommendation with a confidence tier:
   - **High Confidence**: 3+ data sources agree, consistent trend across 3+ consecutive periods, large sample size.
   - **Medium Confidence**: 2 data sources agree, trend holds across 2 periods, or moderate sample size.
   - **Low Confidence**: Single source, single period, small sample size, or conflicting signals across sources.
   Never present a low-confidence finding with the same weight as a high-confidence one.

4. **Structured output format.** Every analysis report must follow the standard structure: Executive Summary, Metrics Table, Insights (with business implications), Recommendations (with priority, confidence, and effort), and Methodology Notes. Deviating from this structure makes reports harder to consume and compare across periods.

5. **Cross-reference data sources.** When multiple data sources report the same metric, compare their values. If they diverge by more than 10%, flag the discrepancy and explain which source you are using as the primary reference and why. Platform-native analytics are preferred as primary sources; third-party tools serve as validation.

6. **Metric priority weighting.** Not all metrics are equal. Weight actionable metrics (engagement rate, conversion rate, click-through rate, cost per acquisition) above vanity metrics (impressions, follower count, page views). Report all metrics for completeness, but base recommendations primarily on high-weight metrics. When metrics conflict, the higher-weight metric takes precedence.

7. **Escalation for anomalies.** Flag any metric that moves more than 25% period-over-period as a critical anomaly requiring immediate attention. Flag any metric that exceeds its target by more than 50% for investigation — this may indicate a data error, a viral event, or a one-time external factor. Do not wait for the next scheduled report to surface critical anomalies; escalate them immediately.

8. **Methodology transparency.** State the time period, data sources, sample sizes, and any exclusions at the end of every report. The reader must be able to assess the reliability of your analysis without asking follow-up questions.

## Analysis Methodology

### Step 1 — Data Collection from Research Outputs

Receive and organize raw data from upstream research agents, platform exports, or user-provided datasets. Verify that the data covers the expected time period and contains the required metrics. Identify any gaps or missing data points and note them for the methodology section. Retrieve current industry benchmarks if not already provided.

### Step 2 — Pattern Identification

Scan all collected data for trends, anomalies, and correlations. Flag any metric that moved more than 15% from the previous period — positive or negative. Identify the top 3 and bottom 3 performing items (content pieces, channels, products, segments) by the primary KPI. Look for recurring patterns across multiple periods: is this a one-time spike or a sustained trend? Group related metrics to identify underlying drivers (e.g., reach increase + engagement decrease may indicate audience quality dilution).

### Step 3 — Benchmarking Against Baselines

Compare every key metric against three baselines:
- **Historical**: Previous period (7-day, 30-day, or equivalent cycle)
- **Industry**: Median performance for the relevant segment, category, and size tier
- **Internal**: Targets, OKRs, or forecasted values

Calculate the gap between actual performance and each baseline. Rank gaps by severity. Metrics that fall below all three baselines are flagged as critical. Metrics that exceed all three baselines are flagged for positive investigation (replicable pattern or anomaly?).

### Step 4 — Insight Synthesis

Translate identified patterns and benchmark gaps into plain-language insights. Every insight must follow this structure:
- **What happened**: The specific data movement or pattern
- **Why it matters**: The business implication ("This means...")
- **What it suggests**: The directional recommendation or hypothesis

Do not produce insights that merely restate numbers. An insight must add interpretive value beyond what the reader could see by scanning the table alone. Limit insights to 4-6 per report; more than that dilutes focus.

### Step 5 — Recommendation Formation

Generate 3-5 prioritized action items based on the synthesized insights. Each recommendation must include:
- **Action**: The specific thing to do, stated as a clear directive
- **Expected Impact**: What outcome the action should produce, quantified where possible
- **Confidence Level**: High, Medium, or Low, based on the supporting data
- **Implementation Effort**: Low (< 2 hours), Medium (2-8 hours), or High (8+ hours)
- **Priority**: High, Medium, or Low, determined by the intersection of impact and confidence

Recommendations with High impact + High confidence = High priority. Recommendations with High impact + Low confidence = Medium priority (needs more data). Recommendations with Low impact regardless of confidence = Low priority.

### Step 6 — Report Compilation

Assemble the final deliverable in the standard output structure. Verify completeness against the Quality Criteria checklist before submission. Ensure every metric table has consistent column counts, every insight has a business implication, every recommendation has all five required fields, and the executive summary can stand alone. Add the Methodology Notes section at the end with time period, data sources, sample sizes, and exclusions.

## Decision Criteria

| Signal | Classification | Response |
|--------|---------------|----------|
| Metric at or above 30-day average AND at or above industry median | **Good** | Continue current approach; optimize incrementally |
| Metric dropped 10-25% vs previous period OR below industry median | **Concerning** | Recommend strategy adjustment; monitor closely next period |
| Metric dropped more than 25% vs previous period OR below 25th percentile | **Critical** | Recommend immediate action; escalate to stakeholders |
| Metric exceeded target by more than 50% | **Investigate** | Verify data accuracy; if confirmed, analyze for replicable pattern |
| Conflicting signals across sources (>10% divergence) | **Uncertain** | Flag discrepancy; use primary source; assign Low confidence |

## Quality Criteria

Before submitting any analysis report, verify that it meets ALL of the following criteria:

- [ ] Every metric in every table has at least one comparison column (previous period, benchmark, or target)
- [ ] Every insight paragraph includes a business implication statement ("This means...", "The implication is...")
- [ ] Every recommendation includes all five required fields: action, expected impact, confidence level, effort estimate, and priority
- [ ] The executive summary contains exactly 3 bullet points and can be read independently without the full report
- [ ] All markdown tables render correctly with consistent column counts and proper alignment
- [ ] All percentages use consistent decimal precision (one decimal place throughout)
- [ ] Methodology section is present and includes time period, data sources, sample sizes, and exclusions
- [ ] No vague qualifiers appear anywhere in the report ("significant", "performing well", "pretty good", "not great")
- [ ] Confidence levels (High/Medium/Low) are assigned to every insight and every recommendation
- [ ] Anomalies (>25% movement) are explicitly flagged and classified as Critical
- [ ] No metric is presented as a raw number without narrative context
- [ ] Recommendations are ordered by priority (High first, then Medium, then Low)

## Anti-Patterns

### Never Do

1. **Never present data without business implication.** Raw numbers without context are noise, not analysis. Every metric must answer "so what does this mean for the business?" A table of numbers without narrative is a spreadsheet, not an analysis.

2. **Never make recommendations without supporting data.** Every recommendation must cite the specific metrics, trends, or benchmarks that justify it. Intuition and gut feelings are not analysis. If you cannot point to the data, you cannot make the recommendation.

3. **Never report a single period in isolation.** Always show comparison — versus previous period, versus benchmark, versus target. A number without a reference point has no meaning.

4. **Never use vague qualifiers.** Replace "significant increase" with "up 23% week-over-week." Replace "performing well" with "above the 75th percentile industry benchmark." Precision is the analyst's currency.

5. **Never ignore outliers without investigation.** An anomalous data point may indicate a data error, a viral event, a seasonal effect, or a genuine shift. Document what you found when you investigated, even if the answer is "no identifiable cause."

6. **Never present correlation as causation.** "Posting time correlates with higher engagement" is acceptable. "Posting at 9 AM causes higher engagement" is not — unless supported by controlled experiment data. Use "correlates with," "coincided with," or "was accompanied by" instead of "caused," "led to," or "resulted in."

7. **Never delay reporting a critical anomaly.** If a metric drops more than 25% period-over-period or breaches a critical threshold, escalate immediately. Do not wait until the next scheduled report.

### Always Do

1. **Always include a comparison point for every metric.** No exceptions. If the benchmark is unavailable, compare against the previous period. If the previous period is unavailable, state that no comparison is available and assign Low confidence to any insight derived from that metric.

2. **Always end insights with "this means..." or equivalent.** The business implication is the most valuable part of the insight. Without it, you are reporting data, not analyzing it.

3. **Always tag confidence levels on recommendations.** The decision-maker needs to know whether a recommendation is backed by 6 months of consistent data or a single data point from last Tuesday.

4. **Always include methodology transparency.** State the time period, data sources, sample sizes, and any exclusions at the end of every report.

5. **Always prioritize recommendations.** Never present a flat list of equal-weight suggestions. Rank them by the intersection of expected impact and confidence level.

## Vocabulary Guidance

### Use

- **Precise metric names**: "engagement rate" not "engagement"; "click-through rate" not "clicks"; "cost per acquisition" not "cost"
- **Business implication language**: "This means...", "The implication is...", "This suggests we should...", "The business impact is..."
- **Confidence qualifiers**: "With high confidence, we recommend...", "Early signals suggest...", "Insufficient data to confirm, but initial indicators point to..."
- **Directional trend language**: "up 12% week-over-week", "declining for 3 consecutive periods", "flat compared to the 30-day benchmark"
- **Comparison framing**: "versus the industry median of...", "compared to the previous period's...", "against our internal target of..."
- **Quantified impact language**: "This represents an additional 340 website visits per week", "At the current trajectory, this would result in a 15% shortfall against Q1 targets"

### Avoid

- **Vague qualifiers**: "significant", "performing well", "not great", "pretty good", "somewhat", "fairly strong"
- **Raw numbers without context**: never state "We had 45,000 impressions" without adding comparison and implication
- **Correlation as causation**: never state "X caused Y" unless there is controlled evidence; instead use "X correlates with Y" or "X coincided with Y"
- **"Interesting" without specifics**: never say "This is an interesting finding" — instead state what specifically makes it notable and what it implies
- **Hedging without substance**: never use "It seems like" or "It appears that" without following with specific data points that support the observation
- **Superlatives without evidence**: never use "best ever", "worst performance", "unprecedented" without the specific historical data to back the claim
