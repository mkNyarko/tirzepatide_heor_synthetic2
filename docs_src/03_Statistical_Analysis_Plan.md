<!-- out: 01_protocol/03_Study_Protocol_and_Statistical_Analysis_Plan.docx -->
# Study Protocol and Statistical Analysis Plan

**Real-World Persistence and Healthcare Costs of Tirzepatide versus Semaglutide 2.4 mg in Commercially Insured Adults with Obesity**

Maxwell K. Nyarko | Version 1.0 | October 7, 2026 | Status: final before outcome analysis

This plan was written and committed to the project's version-control repository (GitHub, commit "SAP v1.0") before any follow-up outcome was derived or compared between groups. Only the cohort feasibility count (number of initiators) was examined before this version. Any later change is listed in Section 13 with its reason.

The data are fully synthetic. Results are a methods demonstration and are not evidence about either drug.

## 1. Objectives and hypotheses

| Aim | Objective | Hypothesis |
|---|---|---|
| 1 (primary) | Compare 12-month persistence (no refill gap > 60 days) and time to discontinuation | H1: tirzepatide has higher persistence and a lower hazard of discontinuation |
| 2 | Compare adherence (PDC; PDC >= 80%) and switching to the other drug | H2: tirzepatide has higher PDC |
| 3 | Compare 12-month all-cause utilization: any inpatient admission, any ED visit, outpatient visits; obesity-related outpatient visits | H3: differences are small |
| 4 | Compare 12-month all-cause medical, pharmacy and total allowed costs (U.S. commercial payer) | H3: total cost differences are driven by pharmacy costs |
| 5 (exploratory) | Effect modification of persistence by obesity class, sex, age group and plan type | No directional hypothesis |
| 6 (exploratory) | Robustness to persistence definitions, cost handling, analytic method and unmeasured confounding | Conclusions unchanged |

## 2. Design

Retrospective new-user, active-comparator cohort study in administrative claims, framed as the emulation of a target trial (Hernán & Robins 2016). Reporting follows RECORD-PE and the TARGET guideline.

### 2.1 Target trial specification and emulation

| Protocol element | Target trial (ideal randomized trial) | Emulation in claims |
|---|---|---|
| Eligibility | Adults 18-64 with obesity, no diabetes, no prior GLP-1 RA, commercially insured, no contraindication | Same, using diagnosis and pharmacy codes in the 365-day baseline; continuous enrollment 365 days before and after index |
| Treatment strategies | Start tirzepatide (Zepbound) vs start semaglutide 2.4 mg (Wegovy) | First pharmacy fill of either drug |
| Assignment | Randomized | Not randomized; confounding addressed with inverse probability of treatment weighting (IPTW) on measured baseline covariates |
| Time zero | Randomization | Index date = first fill (eligibility, assignment and start of follow-up aligned, avoiding immortal time) |
| Follow-up | 12 months | Index date to day 364 |
| Outcomes | Persistence, adherence, switching, utilization, costs | Derived from pharmacy and medical claims |
| Causal contrast | Intention-to-treat effect of initiating each drug | Observational analogue of the intention-to-treat effect (initiation), ATE estimand |
| Analysis | Comparison of randomized groups | IPTW-weighted comparison with robust variance |

## 3. Data source

Synthetic commercial claims extract (members, enrollment, pharmacy claims, medical claims), January 1, 2023 to June 30, 2026, modeled on vendor data such as Optum or MarketScan. Members were selected for at least one fill of an anti-obesity medication or GLP-1 RA. Costs are allowed amounts in nominal U.S. dollars; manufacturer rebates and cash-pay purchases are not observed. A separate data description document gives details.

## 4. Study population

### 4.1 Time windows

| Window | Definition |
|---|---|
| Identification window | January 1, 2024 to June 30, 2025 |
| Index date (time zero) | Date of the first paid fill of Zepbound or Wegovy in the identification window |
| Baseline | Index date - 365 to index date - 1 (diagnoses also accepted on the index date) |
| Follow-up | Index date (day 0) to day 364 |

### 4.2 Inclusion and exclusion criteria (applied in this order; counts reported in a flow diagram)

1. First paid Zepbound or Wegovy fill in the identification window (sets the index date and the treatment group).
2. Only one of the two study drugs filled on the index date.
3. Age 18-64 at index (index year minus birth year); birth year recorded.
4. Sex recorded as female or male, and no conflicting demographic records for the member ID.
5. Continuous medical and pharmacy enrollment from index - 365 through index + 364. Overlapping segments are merged; gaps of 30 days or less are bridged; segments without pharmacy coverage do not count.
6. New user: no fill of any GLP-1 RA (Zepbound, Wegovy, Mounjaro, Ozempic, Rybelsus, Saxenda) in the 365-day baseline.
7. Obesity: at least one diagnosis of E66.x (excluding E66.3 overweight) or BMI code Z68.30-Z68.45 in baseline or on the index date.
8. No diabetes: no E10.x or E11.x diagnosis and no fill of a non-metformin antidiabetic drug (SGLT2 inhibitor, sulfonylurea, insulin, DPP-4 inhibitor) in baseline. Metformin is allowed because it is often used for prediabetes or PCOS; metformin users are removed in a sensitivity analysis.
9. No medullary thyroid carcinoma or MEN 2 code (C73, E31.22) in baseline (boxed-warning contraindication).

## 5. Exposure

Tirzepatide (Zepbound) initiators are the exposed group; semaglutide 2.4 mg (Wegovy) initiators are the comparator. Assignment is fixed at index (intention-to-treat analogue). NDCs are identified with the project NDC lookup after normalizing all NDCs to 11 digits.

## 6. Outcomes (all over the 365-day follow-up)

### 6.1 Primary outcome: persistence

- Supply episodes are built from fills of the index molecule (tirzepatide: Zepbound or Mounjaro; semaglutide: Wegovy, Ozempic or Rybelsus). Early refills are carried forward: a new fill starts the day after the previous supply runs out.
- **Discontinuation** = the first gap of more than 60 days between the end of one supply and the next fill, or between the end of the last supply and day 364. The discontinuation date is the first day without supply.
- **Persistence at 12 months** (binary) = no discontinuation in follow-up.
- **Time to discontinuation** (days); patients without discontinuation are censored at day 365. All patients have full 12-month enrollment, so there is no loss to follow-up.
- Switching to the other molecule ends supply of the index molecule and therefore counts as discontinuation in the primary definition.

### 6.2 Secondary outcomes

| Outcome | Definition |
|---|---|
| PDC | Days covered by the index molecule in days 0-364 divided by 365 (carry-over of early refills, capped at day 364) |
| Adherent | PDC >= 0.80 |
| Switching | Any fill of the other molecule in follow-up |
| Any inpatient admission | Institutional claim with an admission date in follow-up |
| Any ED visit | ED facility claim (place of service 23 or revenue code 0450) or ED E/M code 99281-99285; one visit per day |
| Outpatient visits | Professional E/M office, telehealth or preventive visit (99202-99215, 99381-99397, G0438) at place of service 02, 10, 11, 19 or 22; one visit per day |
| Obesity-related outpatient visits | Outpatient visits with an E66 or Z68 diagnosis on the claim |
| Medical cost | Sum of allowed amounts on medical claims (adjustment lines netted within claim; claim totals floored at $0) |
| Pharmacy cost | Sum of allowed amounts on all paid pharmacy claims (all drugs, including the study drug) |
| Total cost | Medical + pharmacy |

### 6.3 Negative control outcome

Any routine cancer screening (colonoscopy 45378 or screening mammogram 77067) in follow-up. It shares healthcare-seeking confounders with the main outcomes but should not be affected by the choice between the two drugs; a non-null weighted association would suggest residual confounding.

## 7. Covariates

The adjustment set was chosen from the directed acyclic graph (separate DAG document) as variables that plausibly affect both drug choice and the outcomes, measured before or on the index date. Mediators (for example, gastrointestinal adverse events, weight loss, dose escalation, the out-of-pocket cost of the index fill) and post-index variables are not adjusted for.

| Domain | Covariates (baseline unless noted) |
|---|---|
| Demographics | Age (continuous), sex, census region (including Unknown) |
| Benefit design | Plan type at index (PPO, HMO, POS, EPO, CDHP) |
| Calendar time | Index quarter (2024Q1-2025Q2): supply shortages, coverage changes, new indications (Wegovy cardiovascular indication March 2024; Zepbound sleep apnea indication December 2024) |
| Obesity severity | Obesity class from the most recent BMI/class code (Class 1, 2, 3, Unknown) |
| Comorbidities | Hypertension, dyslipidemia, obstructive sleep apnea, prediabetes, MASLD/NASH, osteoarthritis, depression, anxiety, GERD, ASCVD, heart failure, CKD, PCOS, hypothyroidism, gallbladder disease, pancreatitis |
| Medications | Prior other anti-obesity medication (phentermine, naltrexone-bupropion), metformin, antihypertensives, statins, antidepressants, number of distinct generic drugs |
| Healthcare use | Prior bariatric surgery, endocrinologist visit, any inpatient admission, any ED visit, number of outpatient visits, log(1 + total baseline allowed cost) |

## 8. Statistical analysis

### 8.1 Descriptive analysis (Table 1)

Baseline characteristics by group: means (SD) or medians (IQR) for continuous variables, n (%) for categorical variables, with absolute standardized mean differences (SMD) before and after weighting. Cost distributions are inspected for skewness and outliers.

### 8.2 Confounding adjustment

- **Propensity score (PS):** logistic regression of tirzepatide initiation on all covariates in Section 7 (main effects; age and log baseline cost as continuous terms).
- **Weights:** stabilized inverse probability of treatment weights for the average treatment effect (ATE) in the population of initiators (WeightIt).
- **Balance:** absolute SMD < 0.10 for every covariate after weighting (cobalt); variance ratios 0.5-2 for continuous covariates. If balance is not achieved, add squared or interaction terms for the imbalanced covariates (documented as a deviation).
- **Positivity:** inspect PS overlap and the weight distribution; report the effective sample size. Weights are not trimmed in the primary analysis.

### 8.3 Outcome models (weighted; robust sandwich variance)

| Outcome | Model | Effect measure |
|---|---|---|
| Persistence at 12 months (primary) | Weighted linear probability model and weighted log-binomial (Poisson with log link) | Risk difference (RD) and risk ratio (RR), 95% CI |
| Time to discontinuation | Weighted Kaplan-Meier curves; weighted Cox model with robust variance | Hazard ratio (HR); weighted 12-month restricted mean time on treatment if proportional hazards fail |
| PDC | Weighted linear regression | Mean difference |
| PDC >= 80%, switching, any inpatient, any ED | Weighted linear probability and log-link Poisson models | RD and RR |
| Outpatient and obesity-related visit counts | Weighted negative binomial regression (Poisson as a check) | Rate ratio and mean difference |
| Pharmacy and total costs (all > $0) | Weighted gamma GLM with log link | Cost ratio; mean difference with 95% CI from 500 bootstrap replicates that re-estimate the PS |
| Medical cost (includes $0) | Weighted two-part model: logistic (any cost) and gamma-log (positive costs) | Mean difference (bootstrap CI) |

The treatment indicator is the only regressor in the weighted outcome models (marginal effects). Statistical tests are two-sided with alpha = 0.05; secondary outcomes are interpreted with estimates and confidence intervals and are not adjusted for multiplicity.

### 8.4 Model assumption checks

- Proportional hazards: Schoenfeld residual test and plot (cox.zph).
- Cost models: modified Park test for the variance function (gamma implies a coefficient near 2); residual plots; compare with log-normal results if the Park test rejects.
- Count models: overdispersion (Poisson vs negative binomial).
- PS model: overlap plot, c-statistic (reported only for description), extreme weights.

### 8.5 Missing data

- Birth year missing: eligibility cannot be determined; excluded and counted in the flow diagram.
- Sex unknown or conflicting member records: excluded (expected < 1%).
- State missing: "Unknown" region category.
- Missing allowed amounts: imputed deterministically from paid amounts (pharmacy: paid + out-of-pocket; medical: paid / median paid-to-allowed ratio for the claim type).
- Obesity class is unrecorded for many patients because BMI codes are optional. This is not random (likely missing not at random), so multiple imputation under MAR would not remove the bias; "Unknown" is kept as a category and a sensitivity analysis restricts to patients with a recorded class.
- Utilization and costs: absence of a claim means no use (standard in claims; all patients are continuously enrolled).

### 8.6 Subgroup analyses (Aim 5)

Obesity class (1, 2, 3, Unknown), sex, age group (18-44, 45-64) and plan type (CDHP vs non-CDHP), for the primary outcome. Weighted RD and RR in each subgroup and a test of the treatment-by-subgroup interaction in the weighted model. Results are exploratory and are shown in a forest plot.

### 8.7 Sensitivity analyses (Aim 6)

| # | Analysis | Purpose |
|---|---|---|
| S1 | Persistence with a 30-day gap | Definition |
| S2 | Persistence with a 90-day gap | Definition |
| S3 | Persistence on either molecule (switching is not discontinuation) | Definition |
| S4 | 1:1 nearest-neighbour PS matching, caliper 0.2 SD of the logit PS (ATT) | Method |
| S5 | IPTW with weights trimmed at the 1st and 99th percentiles | Positivity |
| S6 | Doubly robust: weighted outcome model that also includes all covariates (g-computation) | Model dependence |
| S7 | Exclude baseline metformin users | Residual diabetes misclassification |
| S8 | Restrict to patients with a recorded obesity class | Missing BMI |
| S9 | Costs winsorized at the 99th percentile | Outliers |
| S10 | E-values for the primary RR and HR | Unmeasured confounding |
| S11 | Negative control outcome (cancer screening) | Residual confounding |

## 9. Sample size and power

Feasibility counts (step 4 of the workflow) found 10,540 first fills of Zepbound or Wegovy in the identification window. Applying the eligibility criteria, which uses only baseline information, left 5,240 patients (2,558 tirzepatide, 2,682 semaglutide); no outcome was looked at. Assuming 12-month persistence of about 60% with semaglutide 2.4 mg (Marshall 2026), this sample gives about 96% power (two-sided alpha 0.05) to detect an absolute difference of 5 percentage points, and 80% power for a difference of about 3.7 percentage points. Weighting reduces the effective sample size, which is reported.

## 10. Table and figure shells

**Table 1. Baseline characteristics by treatment group, before and after weighting**

| Characteristic | Tirzepatide (n = xx) | Semaglutide 2.4 mg (n = xx) | SMD unweighted | SMD weighted |
|---|---|---|---|---|
| Age, mean (SD) | xx (xx) | xx (xx) | x.xx | x.xx |
| Female, n (%) | xx (xx) | xx (xx) | x.xx | x.xx |
| ... | | | | |

**Table 2. Persistence, adherence and switching at 12 months (IPTW)**

| Outcome | Tirzepatide | Semaglutide 2.4 mg | Difference (95% CI) | Ratio (95% CI) |
|---|---|---|---|---|
| Persistent at 12 months, % | xx | xx | RD xx (xx, xx) | RR xx (xx, xx) |
| Time to discontinuation | | | | HR xx (xx, xx) |
| PDC, mean | xx | xx | xx (xx, xx) | |
| PDC >= 80%, % | xx | xx | xx | xx |
| Switched, % | xx | xx | xx | xx |

**Table 3. Healthcare utilization and costs at 12 months (IPTW)**

| Outcome | Tirzepatide | Semaglutide 2.4 mg | Difference (95% CI) | Ratio (95% CI) |
|---|---|---|---|---|
| Any inpatient admission, % | | | | |
| Any ED visit, % | | | | |
| Outpatient visits, mean | | | | |
| Medical cost, mean $ | | | | |
| Pharmacy cost, mean $ | | | | |
| Total cost, mean $ | | | | |

**Table 4. Subgroup and sensitivity analyses for 12-month persistence**

| Analysis | N | Tirzepatide % | Semaglutide % | RD (95% CI) | RR (95% CI) |
|---|---|---|---|---|---|
| Primary | | | | | |
| S1-S11 ... | | | | | |

**Figures:** (1) cohort flow diagram; (2) propensity score overlap; (3) covariate balance (Love plot); (4) weighted Kaplan-Meier curves for time to discontinuation; (5) cost distributions by group; (6) subgroup forest plot; (7) sensitivity analysis forest plot.

## 11. Software and reproducibility

R 4.4.1 (x86_64-apple-darwin20), macOS 15.7.9, locale en_US.UTF-8, time zone America/New_York. Main packages: dplyr, WeightIt, MatchIt, cobalt, survival, sandwich, MASS, EValue, dagitty. Random seed 20261007. Code is in numbered scripts (05_code) and in one annotated R Markdown file; all derived data can be rebuilt from the raw extract.

## 12. Ethics, data governance and registration

The data are fully synthetic and contain no information about real people, so this project is not human-subjects research and needs no IRB review or data use agreement. A study on real claims would need an IRB exemption determination (de-identified data under HIPAA) and the vendor's data use agreement. For a real study this protocol would be registered (for example on the OSF registry or the HMA-EMA RWD Catalogue, formerly the EU PAS Register) before analysis. Here, the commit history of the GitHub repository time-stamps this plan before the outcome analysis.

## 13. Amendments after version 1.0

None at the time of writing. Any deviation found during analysis is recorded here and in the summary document, with the reason.
