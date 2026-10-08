<!-- out: 07_reports/05_Research_Step_Summary.docx -->
# Research Step Summary

**Tirzepatide vs semaglutide 2.4 mg: persistence, utilization and costs in commercially insured adults with obesity (synthetic claims)**

Maxwell K. Nyarko | October 7-8, 2026

This document records every step taken to answer the research question, from start to finish, with the decision made at each step and the reason for it. It follows the 12-step workflow in `Research_Question_Workflow.docx`. The analysis steps (workflow steps 7-10) list every action carried out in R and why; the code itself is in `HEOR_Tirzepatide_Analysis.Rmd` and `05_code/`.

The data are fully synthetic; all results are a methods demonstration.

## Overview of decisions

| Workflow step | Key decision | Rationale |
|---|---|---|
| 1. Question and aims | PECO question on 12-month persistence (primary) plus adherence, switching, utilization and costs; U.S. commercial payer perspective; 12-month horizon | Persistence drives the value of both drugs; no adjusted U.S. commercial comparison existed |
| 2. Literature | Keep aims; adopt the 60-day gap, PDC >= 80%, new-user washout; list confounders | Confirmed gap; aligns definitions with the U.S. commercial benchmark (Marshall 2026) |
| 3. Design | Active-comparator new-user cohort emulating a target trial; first fill = time zero; DAG-based adjustment set | Avoids prevalent-user and immortal time bias; makes assumptions explicit |
| 4. Data and feasibility | Synthetic commercial claims; 10,540 initiators -> 5,240 eligible | Claims capture fills and payer costs; > 95% power for a 5-point difference |
| 5. SAP | IPTW (ATE), weighted GLMs with robust SEs, gamma/two-part cost models, bootstrap CIs; 4 subgroups; 11 sensitivity analyses | Pre-specification protects against data-driven choices |
| 6. Ethics/registration | Not human-subjects research; SAP time-stamped in Git before outcomes | Synthetic data; Git history serves as registration |
| 7. Data management | 28 data-quality checks with logged decisions; 9-step cohort flow | Transparent, reproducible cleaning |
| 8. Descriptives | Table 1 with SMDs; skewness of costs inspected | Shows comparability and justifies cost models |
| 9. Main models | Balance achieved (max weighted SMD 0.01); PH assumption held; Park test pointed to a heavier variance than gamma (handled per SAP) | Confirms model assumptions |
| 10. Robustness | Subgroups homogeneous; all sensitivity analyses agree; negative control null; E-value 1.54 | Supports a robust finding |
| 11. Interpretation | Tirzepatide: +7 points persistence, lower pharmacy and total allowed cost; no medical-cost difference | Effect sizes with CIs, payer translation |
| 12. Write-up | Paper following RECORD-PE and TARGET, with checklist | Complete reporting |

## Step 1. Research question, knowledge gap and aims

- **What was done:** the topic, background, PECO question, aims and hypotheses were set out in `Research_Question_and_Aims.docx` (completed before this automated run and accepted without change after review).
- **Decisions:** primary outcome = 12-month persistence; secondary = PDC, switching, utilization, all-cause costs; exploratory = subgroups and robustness. Perspective = U.S. commercial payer; time horizon = 12 months.
- **Why:** persistence determines how much of the trial benefit (SURMOUNT-5) is realized, and payers need cost data for coverage decisions.

## Step 2. Literature review, then refine the aims

- **What was done:** the PubMed search (146 records, 10 retained) from the protocol was re-read in full text, and 8 context and methods sources were added. Two synthesis tables were built (`02_Literature_Review_and_Synthesis.docx`).
- **Decisions:** (a) aims unchanged: the gap (no adjusted U.S. commercial comparison of persistence, no cost or utilization comparison without T2D) was confirmed; (b) 60-day gap as the primary persistence definition to match Marshall 2026, with 30- and 90-day gaps as sensitivity analyses, because definitions in the literature range from 30 to 90 days; (c) a 365-day GLP-1 washout, because prior GLP-1 exposure changes persistence (Hoog 2026); (d) confounders and effect modifiers taken from the literature: age, sex, obesity severity, cardiometabolic comorbidities and new indications, benefit design, calendar time.
- **Why:** using benchmark definitions makes the results comparable with prior work; listing confounders before seeing data feeds the DAG.

## Step 3. Study design, time windows and DAG

- **What was done:** the design was specified as a target trial emulation (SAP Section 2.1) and two DAGs were coded with dagitty (`05_code/00b_dag.R`; `04_Directed_Acyclic_Graphs.docx`).
- **Decisions:**
  - Active comparator (semaglutide 2.4 mg) rather than non-users, to reduce confounding by indication.
  - New users only; index date = first fill, so eligibility, assignment and follow-up start on the same day (no immortal time).
  - Identification window January 2024 to June 2025: Zepbound was launched in November 2023, and every index date then has 365 days of baseline data (data start January 2023) and 365 days of follow-up (data end June 2026).
  - Obesity-labeled products only (Zepbound, Wegovy); diabetes-labeled products count as prior GLP-1 use (exclusion) and, during follow-up, as fills of the same molecule.
  - Adjustment set from dagitty: age, sex, region, plan type, calendar time, obesity severity, comorbidity, prior anti-obesity medication, baseline utilization, endocrinologist care. Mediators (GI adverse events, weight loss, the index drug's out-of-pocket cost, persistence for costs) were deliberately not adjusted for.
- **Why:** these choices remove the most common biases in drug comparisons using claims and make the causal assumptions explicit.

## Step 4. Data source and feasibility

- **What was done:** the extract was profiled (row counts, code formats, coverage of study drugs) and the eligible cohort was counted before any outcome was derived. The data description document explains why claims fit the question and what features make the extract claims data.
- **Decisions:** the data can answer the question: fills with days supply (persistence), allowed amounts (costs), place of service, revenue and CPT codes (utilization) and diagnoses (eligibility, confounders) are all present. Limitations accepted: no BMI values, no reasons for stopping, no cash-pay fills, no rebates.
- **Feasibility:** 10,540 first fills in the window, 5,240 eligible (2,558 tirzepatide, 2,682 semaglutide). About 96% power for a 5-point difference in persistence; aims not revised.

## Step 5. Protocol and SAP with key decisions pre-specified

- **What was done:** the study protocol and SAP were written (`03_Study_Protocol_and_Statistical_Analysis_Plan.docx`) with operational definitions, covariates, models, missing-data plan, subgroups, 11 sensitivity analyses and table/figure shells.
- **Decisions and reasons:**
  - **Estimand:** ATE among initiators, intention-to-treat analogue (treatment fixed at index), matching the target trial.
  - **Confounding:** stabilized IPTW from a logistic PS model (keeps all patients, estimates the ATE, and weights stay near 1); balance target |SMD| < 0.10.
  - **Models:** weighted linear and log-link models for risk differences and ratios; weighted Cox and Kaplan-Meier for time to discontinuation; negative binomial for overdispersed counts; gamma-log GLM for positive skewed costs; two-part model for medical costs with zeros; robust (sandwich) variance; bootstrap CIs (500 replicates re-estimating the PS) for cost differences.
  - **Missing data:** exclusions for missing birth year and unknown or conflicting sex; "Unknown" categories for region and obesity class; deterministic imputation of missing allowed amounts. Multiple imputation was not used because missing BMI coding is likely not at random and few other values were missing.
- **Why:** writing all of this before analysis stops results from steering choices.

## Step 6. Ethics, IRB and registration

- **Decision:** no IRB review or data use agreement needed (fully synthetic data, no human subjects). For a real study: IRB exemption, vendor DUA, and registration on OSF or the HMA-EMA RWD Catalogue.
- **What was done instead:** the SAP and DAGs were committed and pushed to GitHub (commit "SAP v1.0, DAGs and data-management code (pre-specified before outcome analysis)") before any outcome was derived, giving a time-stamped record.

## Step 7. Data management, cleaning and the analytic cohort

Each action below is a step in the R code (Rmd Steps 2-8; scripts 01-07), with its rationale.

**7a. Import (script 01)**

1. Read every code column (NDC, ICD-10, CPT, revenue, place of service) as text. *Why:* numeric reading drops leading zeros and breaks code matching.
2. Stack the yearly claim files and save raw copies without changes. *Why:* the raw data stay as delivered and every later step is traceable.
3. Check row counts and parsing problems (none). *Why:* to catch truncated or malformed files early.

**7b. Data-quality review (script 02):** 28 checks were logged with a decision for each (`06_output/tables/data_quality_log.csv`; summarized in the data description). Main findings: three NDC formats, 10,535 reversals, duplicate rows in every table, lower-case and mixed-format ICD-10 codes, missing and negative amounts, implausible days supply (0-2, 365, 999), overlapping enrollment segments and 22 member IDs with conflicting sex. *Why:* finding problems before cleaning means each fix is deliberate and documented.

**7c. Clean members and enrollment (script 03)**

1. Drop exact duplicate member rows and flag IDs with conflicting demographics. *Why:* the true sex/age of a conflicting ID is unknowable.
2. Add census region from state ("Unknown" if missing). *Why:* region is a confounder.
3. Keep enrollment segments with both medical and pharmacy coverage. *Why:* pharmacy claims are captured only with drug coverage.
4. Merge overlapping segments and bridge gaps of 30 days or less into continuous spans (93,669 segments -> 15,257 spans). *Why:* a 30-day allowance is a common convention and avoids excluding people for administrative breaks.

**7d. Clean claims (script 04)**

1. Normalize all NDCs to 11 digits; all matched the lookup. *Why:* otherwise about 30% of fills (hyphenated or truncated codes) would be missed.
2. Remove reversals and the claims they reverse; keep one row per claim ID. *Why:* reversed fills were never dispensed; duplicates double-count.
3. Impute missing pharmacy allowed amounts as paid + out-of-pocket. *Why:* this identity holds in every complete row.
4. Replace 935 implausible days-supply values with the usual value for that NDC and quantity. *Why:* days supply drives persistence and PDC.
5. Standardize ICD-10 codes (upper case, no dot) and place of service; drop duplicate lines (646,831 -> 641,723 lines). *Why:* consistent codes; no double counting.
6. Impute 1,909 missing medical allowed amounts from paid amounts (median paid/allowed ratio by claim type). *Why:* keeps costs complete with a simple, documented rule.
7. Keep negative adjustment lines and net them within each claim, flooring claims at $0. *Why:* adjustments are part of the final allowed amount.

**7e. Build the cohort (script 05).** The criteria were applied in SAP order, with counts saved (`attrition.csv`) and drawn as Figure 1:

| Step | Criterion | N remaining | Excluded |
|---|---|---|---|
| 1 | First Zepbound or Wegovy fill, Jan 2024-Jun 2025 | 10,540 | |
| 2 | One study drug on the index date | 10,512 | 28 |
| 3 | Age 18-64 with birth year | 9,970 | 542 |
| 4 | Known sex, no conflicting records | 9,911 | 59 |
| 5 | Continuous enrollment 365 days before and after | 7,469 | 2,442 |
| 6 | No GLP-1 RA fill in baseline (new user) | 6,637 | 832 |
| 7 | Obesity diagnosis | 5,660 | 977 |
| 8 | No diabetes | 5,251 | 409 |
| 9 | No thyroid cancer / MEN 2 code | 5,240 (2,558 tirzepatide; 2,682 semaglutide) | 11 |

Plan type was taken from the enrollment segment covering the index date, and the index quarter was added. *Why:* each criterion puts one element of the PECO question and the target trial into practice.

**7f. Baseline covariates (script 06)**

1. Express every claim as days relative to index. *Why:* each window becomes a simple filter.
2. Define encounters once (inpatient admission, ED visit, outpatient E/M visit, obesity-related outpatient visit; one per member per day) and claim-level medical costs. *Why:* the same definitions serve as baseline covariates and follow-up outcomes.
3. Flag 16 comorbidities from diagnoses in [index - 365, index], and obesity class from the most recent BMI/class code. *Why:* DAG confounders.
4. Count baseline utilization and costs, distinct generic drugs, endocrinologist visits, and bariatric surgery history. *Why:* proxies for health status and care-seeking.
5. Flag baseline medication classes. *Why:* treatment history and comorbidity severity.
6. Log-transform baseline cost. *Why:* reduce the influence of extreme costs on the PS model.
- **Finding:** no cohort member had a prior phentermine or naltrexone-bupropion fill (the 973 users of these drugs never met the criteria), so this covariate was constant and contributed nothing; it was kept as pre-specified.

**7g. Outcomes (script 07)**

1. Keep follow-up fills (days 0-364) of tirzepatide (Zepbound, Mounjaro) and semaglutide (Wegovy, Ozempic, Rybelsus). *Why:* persistence is on the index molecule; fills of the other molecule mark switching.
2. Persistence function: lay fills end to end with carry-over of early refills; discontinuation = first gap > 60 days (including after the last fill); PDC = days covered / 365. *Why:* the standard claims definitions (Marshall 2026).
3. Run the function with 60-, 30- and 90-day gaps and on either molecule. *Why:* the primary outcome and sensitivity analyses S1-S3 come from one function.
4. Flag switching; count follow-up encounters; sum medical, pharmacy, study-drug and out-of-pocket costs; flag the negative control outcome (colonoscopy or screening mammogram). *Why:* Aims 2-4 and bias analysis.
5. Crude results (before weighting): persistence 57.9% vs 51.1%; total cost $13,717 vs $15,602 (tirzepatide vs semaglutide).
- **Note:** with a 60-day gap, a discontinuation can only be observed if supply runs out by about day 303, so the Kaplan-Meier curves are flat after that point. This is a property of the definition and applies to both groups equally.

## Step 8. Descriptive analysis (Table 1)

1. Fit the propensity score model (logistic regression on the 34 covariates) and compute stabilized ATE weights (WeightIt). *Why:* to balance measured confounders.
2. Check balance with cobalt: the largest absolute SMD fell from 0.23 (baseline outpatient visits) to 0.01 after weighting; variance ratios were close to 1. *Why:* the SAP threshold was 0.10.
3. Inspect the weights: range 0.57-6.53, mean 1.00; effective sample size 2,376 (tirzepatide) and 2,558 (semaglutide). *Why:* extreme weights would signal positivity problems; none were found, so no trimming was needed (trimming was tested in S5).
4. Build Table 1 (unweighted and weighted) and plot PS overlap (Figure 2) and the Love plot (Figure 3). *Why:* to describe the population and show comparability.
- **Findings:** before weighting, tirzepatide initiators were slightly younger (44.2 vs 45.5 years), started later in the window, had less ASCVD (3.3% vs 6.4%; consistent with Wegovy's cardiovascular indication), more sleep apnea (36.0% vs 32.1%; consistent with Zepbound's sleep apnea indication) and fewer baseline visits. Costs were highly right-skewed (baseline medical cost SD about $18,000-26,000 around means near $5,000), confirming the need for log-scale PS terms and gamma/two-part models. Weighted mean baseline cost in dollars remained higher in the tirzepatide group because of a few very expensive patients, although log cost was balanced.

## Step 9. Main models, assumption checks and model fit

1. **Primary outcome.** Weighted linear and log-link models with robust SEs: persistence 58.0% vs 50.8%, RD +7.1 points (95% CI 4.3-9.9), RR 1.14 (1.08-1.20). *Why:* Aim 1 on both the absolute and relative scales.
2. **Time to discontinuation.** Weighted Kaplan-Meier (Figure 4) and Cox model: HR 0.81 (0.75-0.88). Restricted mean time on treatment: 266 vs 250 days (+16.5 days; bootstrap CI 9.2-24.0). *Why:* Aim 1; RMST is easy to explain.
3. **Proportional hazards check.** Schoenfeld test p = 0.41: assumption held, so the HR is a valid summary.
4. **Adherence and switching.** PDC 64.1% vs 60.3% (+3.8 points, 2.2-5.4); PDC >= 80% 45.9% vs 40.5% (RR 1.13, 1.06-1.21); switching 2.2% vs 8.9% (RR 0.25, 0.18-0.33). *Why:* Aim 2.
5. **Utilization.** Any inpatient 4.2% vs 4.7% (RR 0.89, 0.68-1.15); any ED 23.2% vs 24.6% (RR 0.94, 0.85-1.04); outpatient visits 5.6 vs 5.8 (rate ratio 0.97, 0.92-1.01); obesity-related visits 3.4 vs 3.5 (0.96, 0.91-1.01). *Why:* Aim 3.
6. **Overdispersion check.** Poisson dispersion 3.0 (outpatient) and 2.5 (obesity-related): negative binomial justified.
7. **Costs.** Medical $4,420 vs $4,327 (+$92; bootstrap CI -$1,323 to +$1,395); pharmacy $9,403 vs $11,197 (-$1,794; -$2,055 to -$1,530; ratio 0.84); total $13,822 vs $15,524 (-$1,702; -$3,033 to -$371; ratio 0.89, 0.81-0.98). Study-drug cost alone: $9,308 vs $11,102. *Why:* Aim 4.
8. **Cost model check (modified Park test).** Slope 3.58, closer to an inverse Gaussian variance than to gamma (2). As planned in the SAP, the total-cost ratio was re-estimated under an inverse Gaussian GLM and a log-normal model with smearing: all three gave 0.890 (identical, as expected when treatment is the only regressor; only the standard errors could differ, and the robust CIs were the same). The bootstrap CIs for cost differences do not depend on the variance function. *Decision:* keep the gamma results as primary. This is a pre-specified contingency, not a deviation.
9. **Medical cost zeros.** Only 2.3% of patients had $0 medical cost; the two-part model was kept as planned.

**Interpretation of the cost result:** tirzepatide patients stayed on treatment longer yet had lower pharmacy costs, because the allowed amount per fill was lower for Zepbound than for Wegovy in this extract (median $1,065 vs $1,323). This is a feature of the synthetic prices; real net prices after rebates differ.

## Step 10. Subgroup, interaction, sensitivity and bias analyses

1. **Subgroups (Aim 5).** RR for persistence by obesity class 1.14 / 1.06 / 1.20 / 1.13 (classes 1, 2, 3, unknown; interaction p = 0.39); sex 1.13 (female) and 1.16 (male; p = 0.62); age 1.18 (18-44) and 1.11 (45-64; p = 0.29); plan 1.15 (non-CDHP) and 1.10 (CDHP; p = 0.50). *Decision:* no evidence of effect modification; subgroup differences are reported as exploratory. *Why:* interaction tests protect against over-reading chance variation.
2. **Sensitivity analyses (Aim 6):**

| Analysis | RD (95% CI), points | RR (95% CI) |
|---|---|---|
| Primary (IPTW, 60-day gap) | 7.1 (4.3, 9.9) | 1.14 (1.08, 1.20) |
| S1 30-day gap | 5.4 (2.7, 8.1) | 1.15 (1.07, 1.23) |
| S2 90-day gap | 7.4 (4.6, 10.1) | 1.14 (1.08, 1.19) |
| S3 Either drug (switching allowed) | 3.9 (1.2, 6.7) | 1.07 (1.02, 1.12) |
| S4 1:1 PS matching (2,354 pairs, ATT) | 6.7 (3.9, 9.6) | 1.13 (1.07, 1.19) |
| S5 Trimmed weights | 7.0 (4.2, 9.7) | 1.14 (1.08, 1.20) |
| S6 Doubly robust | 7.1 (4.4, 9.8) | 1.14 (1.08, 1.20) |
| S7 Excluding metformin users | 6.5 (3.7, 9.3) | 1.13 (1.07, 1.19) |
| S8 Recorded obesity class only | 7.2 (4.0, 10.3) | 1.14 (1.08, 1.21) |
| S9 Costs winsorized at 99th percentile | Total -$1,936; pharmacy -$1,759; medical -$160 | Total ratio 0.87 |
| S10 E-values | RR 1.54 (CI limit 1.38); HR 1.58 (CI limit 1.40) | |
| S11 Negative control (cancer screening) | -0.4 (-1.9, 1.1) | 0.94 (0.75, 1.17) |

- **Why each:** S1-S3 test the outcome definition (S3 is smaller because many semaglutide patients who "discontinued" had switched to tirzepatide); S4-S6 test the analytic method; S7-S8 test the handling of possible diabetes misclassification and missing BMI; S9 tests cost outliers; S10-S11 probe unmeasured confounding. The E-value (VanderWeele & Ding 2017) is the minimum strength of association, on the risk ratio scale, that an unmeasured confounder would need with both drug choice and persistence to explain away the result.
- **Matching balance:** after matching, all covariate SMDs were below 0.08 (the larger value printed by cobalt for the propensity score "distance" itself, 0.16, is not a covariate). The script was updated to report covariates only.

## Step 11. Interpretation

- Tirzepatide initiation was associated with 7 more patients per 100 persisting at 12 months (number needed to treat about 14) and about 16 more days on treatment, with higher adherence and much less switching. H1 and H2 supported.
- Utilization did not differ meaningfully; medical costs were similar; total cost differences were driven by pharmacy costs. H3 supported, with the direction (lower pharmacy cost for tirzepatide) explained by the lower per-fill allowed amount in these data.
- The finding was robust to definitions, methods, outliers and missing BMI; the negative control was null; an unmeasured confounder would need RR >= 1.54 with both drug choice and persistence to explain away the point estimate (E-value; VanderWeele & Ding 2017).
- **Comparison with the literature:** the RD (7 points) lies between the unadjusted commercial estimate (about 6 points; Marshall 2026) and the military estimate (11 points; Miller 2026); the HR (0.81) is weaker than Miller's 0.67, plausibly because cost sharing reduces persistence in both groups. Similar hospitalization/ED use agrees with Qadeer 2026.
- **For payers:** if per-fill prices were as in these data, tirzepatide would deliver more treatment-days at lower total allowed cost (a dominant result over 12 months); in reality the net-price difference after rebates determines this.

## Step 12. Write-up

- The research paper (`06_Research_Paper.docx`) follows RECORD-PE and the TARGET guideline and cites all 18 sources in the literature folder plus the E-value methods paper (19 references); the checklist (`07_Reporting_Checklist_RECORD-PE.docx`) maps each item to the paper.
- Code and materials: GitHub repository (scripts 00-10, the annotated R Markdown, all tables and figures, Markdown sources of all documents). Derived data and copyrighted literature are not shared.

## Process notes and deviations from the SAP

| Item | What happened | Effect on results |
|---|---|---|
| SAP amendment (power section) | Updated with the final eligible N (5,240) before outcomes were derived | None |
| Cost variance function | Park test slope 3.58; pre-specified alternative models run | None (identical ratios) |
| Prior anti-obesity medication | Constant (0%) in the cohort | Covariate uninformative |
| Code corrections during the run | Three bugs found and fixed before results were used: a column-name masking error in the subgroup and cost-table helpers, a vector name carried into the two-part cost ratio, and a missing package dependency (chk) for MatchIt | None on the estimates; fixes are in the committed code |
| Matching balance message | Reported the PS distance with the covariates; changed to covariates only | None |
| E-value reference (October 8, 2026) | The E-value method paper (VanderWeele & Ding 2017) had been cited only in the paper's reference list. It was added to the literature review (Table B, synthesis point 6), the SAP (S10; recorded as editorial amendment v1.1), the DAG document, this summary and the R Markdown, and the open-access author manuscript was saved to the literature folder | None |
| Paper revision (October 8, 2026) | The paper originally cited 11 of the 18 literature-folder sources, and Hoog 2026 appeared only in the reference list. The Introduction, Methods and Discussion were revised so that all 18 sources plus VanderWeele & Ding 2017 are cited in the text (19 references) | None on results |
| Computing environment | R 4.4.1 on macOS 15.7.9, en_US.UTF-8, America/New_York; packages installed from CRAN | n/a |

## Deliverables produced

| Deliverable | File | Status |
|---|---|---|
| Research question and aims | `01_protocol/Research_Question_and_Aims.docx` | Existing; reviewed and accepted unchanged |
| Data description | `01_protocol/01_Data_Description.docx` | New |
| Literature review and synthesis | `01_protocol/02_Literature_Review_and_Synthesis.docx` | New (builds on the protocol's Appendix A) |
| Protocol and SAP | `01_protocol/03_Study_Protocol_and_Statistical_Analysis_Plan.docx` | New |
| DAGs | `01_protocol/04_Directed_Acyclic_Graphs.docx` | New |
| Annotated R Markdown | `HEOR_Tirzepatide_Analysis.Rmd` | New |
| R scripts | `05_code/00-10` | Completed from templates |
| Research step summary | `07_reports/05_Research_Step_Summary.docx` | This document |
| Research paper | `07_reports/06_Research_Paper.docx` | New |
| Reporting checklist | `07_reports/07_Reporting_Checklist_RECORD-PE.docx` | New |
| Tables and figures | `06_output/` | New |
