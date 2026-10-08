<!-- out: 07_reports/06_Research_Paper.docx -->
# Twelve-Month Persistence, Healthcare Utilization and Costs of Tirzepatide versus Semaglutide 2.4 mg in Commercially Insured Adults with Obesity: A Target Trial Emulation in Synthetic Claims Data

Maxwell K. Nyarko

**Methods demonstration.** All analyses were performed on a fully synthetic claims dataset generated for training. The results describe the simulated data only and should not be read as evidence about either drug.

## Abstract

**Objective.** To compare 12-month treatment persistence, adherence, healthcare resource utilization and all-cause costs between new users of tirzepatide (Zepbound) and semaglutide 2.4 mg (Wegovy) among commercially insured adults with obesity and without diabetes.

**Methods.** A target trial was emulated in a synthetic U.S. commercial claims extract (January 2023-June 2026). Adults aged 18-64 years were included if they had an obesity diagnosis, no diabetes, no GLP-1 receptor agonist use in the prior 365 days, and continuous enrollment for 365 days before and after their first fill (index date) between January 2024 and June 2025. Confounding was addressed with stabilized inverse probability of treatment weights from a propensity score that included demographics, plan type, calendar quarter, obesity class, comorbidities, medications, and baseline utilization and costs. The primary outcome was persistence at 12 months (no refill gap longer than 60 days). Secondary outcomes were time to discontinuation, proportion of days covered (PDC), switching, inpatient, emergency department (ED) and outpatient use, and medical, pharmacy and total allowed costs.

**Results.** Of 10,540 initiators, 5,240 were eligible (2,558 tirzepatide; 2,682 semaglutide). After weighting, no standardized mean difference exceeded 0.01. Persistence at 12 months was 58.0% with tirzepatide and 50.8% with semaglutide (risk difference 7.1 percentage points, 95% CI 4.3-9.9; risk ratio 1.14, 1.08-1.20), and the hazard ratio for discontinuation was 0.81 (0.75-0.88). PDC was higher with tirzepatide (64.1% vs 60.3%), and switching was less common (2.2% vs 8.9%). Inpatient, ED and outpatient use did not differ meaningfully. Mean 12-month medical costs were similar ($4,420 vs $4,327). Pharmacy costs ($9,403 vs $11,197) and total costs ($13,822 vs $15,524; difference -$1,702, 95% CI -$3,033 to -$371) were lower with tirzepatide because its allowed amount per fill was lower in these data. The results held in 11 sensitivity analyses; the negative control outcome was null and the E-value was 1.54.

**Conclusions.** In this simulated population, initiation of tirzepatide rather than semaglutide 2.4 mg was associated with higher 12-month persistence and adherence, no difference in medical utilization, and lower total allowed costs driven by pharmacy prices. The same pre-specified, confounding-adjusted design can be applied to real claims to supply the persistence and cost inputs used in payer decisions and economic models.

\newpage

## Introduction

In the head-to-head SURMOUNT-5 trial, the dual GIP/GLP-1 receptor agonist tirzepatide produced greater weight loss than semaglutide 2.4 mg (-20.2% vs -13.7% at 72 weeks; Aronne 2025). That benefit holds only while patients stay on treatment. In SURMOUNT-4, stopping tirzepatide led to substantial weight regain (Aronne 2024), and in routine care more than one in five patients stop within three months, with much smaller weight loss among early discontinuers (Gasoyan 2025).

Real-world comparisons of the two drugs have mostly examined weight change and tolerability. These studies were conducted with the diabetes-labeled products (Rodriguez 2024), in single clinics or programs (Samuels 2025; Cetiner 2026; Richards 2025), outside the United States (Hepşen 2026; Cetiner 2026; Richards 2025), or only in patients who stayed on treatment or completed a program (Ng 2025; Cetiner 2026; Richards 2025). Tirzepatide was associated with greater weight loss in each of them, but none was designed to compare persistence or costs. One-year persistence in U.S. commercial claims has been reported without adjustment for confounding, and the figures vary by year (Marshall 2026; Prime Therapeutics 2025). The only adjusted comparison comes from active-duty military personnel, who have no cost sharing (Miller 2026; HR for discontinuation 0.67). In type 2 diabetes, persistence and adherence were higher among tirzepatide initiators (Hoog 2026), and hospitalization or ED use was similar between the drugs (Qadeer 2026). All-cause healthcare utilization and costs have not been compared between the two drugs in adults with obesity without diabetes. Published cost-effectiveness models also disagree widely, mainly because they assume different treatment durations and prices (ICER 2025; Hwang 2025).

The aim of this study was to compare 12-month persistence (primary aim), adherence and switching, healthcare utilization, and all-cause costs between new users of tirzepatide and semaglutide 2.4 mg from a U.S. commercial payer perspective, using a pre-specified target trial emulation. Tirzepatide was expected to show higher persistence and adherence, with little difference in medical utilization and costs, so that any difference in total costs would come from pharmacy costs.

## Methods

### Design

A retrospective new-user, active-comparator cohort study was designed as the emulation of a target trial (Hernán & Robins 2016). The protocol and statistical analysis plan (SAP), including the directed acyclic graphs (DAGs), were committed to a version-controlled repository before any outcome was derived. Reporting follows RECORD-PE (Langan 2018) and the TARGET guideline.

| Element | Target trial | Emulation |
|---|---|---|
| Eligibility | Adults 18-64, obesity, no diabetes, no prior GLP-1 RA, commercially insured | Diagnosis and pharmacy codes in a 365-day baseline; continuous enrollment |
| Strategies | Start tirzepatide vs start semaglutide 2.4 mg | First fill of Zepbound vs Wegovy |
| Assignment | Random | Inverse probability of treatment weighting on measured confounders |
| Time zero | Randomization | First fill (eligibility, assignment and follow-up aligned) |
| Follow-up | 12 months | Index to day 364 |
| Causal contrast | Intention-to-treat | Observational analogue (treatment fixed at index); average treatment effect |

### Data source

Data came from a synthetic commercial claims extract built to resemble vendor databases such as Optum and MarketScan. It contained member demographics (birth year, sex, state); enrollment segments with plan type and separate medical and pharmacy coverage; pharmacy claims (NDC, fill date, days supply, quantity, allowed amounts); and medical claims (ICD-10-CM diagnoses, CPT/HCPCS codes, revenue codes, place of service, allowed amounts) from January 2023 to June 2026. All members had at least one fill of an anti-obesity medication or GLP-1 RA. Costs are allowed amounts in nominal dollars; rebates and cash-pay purchases are not captured.

### Data management

A data-quality review of 28 checks was completed before cleaning. NDCs recorded in three formats were converted to 11 digits. Reversed pharmacy claims were removed together with the claims they reversed, and duplicate records were dropped. ICD-10 codes were standardized. Implausible days-supply values (0-2, 365 or 999 days; n = 935 after cleaning) were replaced with the usual value for the NDC and quantity, missing allowed amounts were imputed from paid amounts, and negative adjustment lines were netted within claims. Enrollment segments with both medical and pharmacy coverage were merged into continuous spans, with gaps of 30 days or less bridged.

### Study population

The index date was defined as the first Zepbound or Wegovy fill between January 1, 2024 and June 30, 2025. Patients were included if they filled only one study drug on the index date; were aged 18-64 years; had a known sex and no conflicting records; were continuously enrolled from 365 days before to 364 days after index; had no fill of any GLP-1 RA (Zepbound, Wegovy, Mounjaro, Ozempic, Rybelsus, Saxenda) in the 365-day baseline; had an obesity diagnosis (E66 excluding E66.3, or BMI code Z68.30-Z68.45) in baseline or on the index date; had no diabetes (no E10/E11 code and no non-metformin antidiabetic drug); and had no code for medullary thyroid cancer or MEN 2.

### Exposure

Tirzepatide initiators formed the exposed group and semaglutide 2.4 mg initiators the comparator group. Exposure was fixed at the index date.

### Outcomes

Persistence was constructed from fills of the index molecule (tirzepatide: Zepbound or Mounjaro; semaglutide: Wegovy, Ozempic or Rybelsus), with early refills carried forward. Discontinuation was defined as the first gap of more than 60 days without supply, including the period after the last fill, and persistence at 12 months as the absence of discontinuation. Published gap definitions range from 30 to 90 days (Ng 2025; Hoog 2026; Samuels 2025; Miller 2026; Gasoyan 2025). A 60-day gap was chosen to match the U.S. commercial benchmark (Marshall 2026; Prime Therapeutics 2025), and 30- and 90-day gaps were tested in sensitivity analyses. Time to discontinuation was measured from index to the first day without supply. Because a gap had to exceed 60 days within follow-up, discontinuation could be observed only when supply ended by about day 303. PDC was calculated as days covered divided by 365, and adherence was defined as PDC >= 80%. Switching was defined as any fill of the other molecule. Utilization outcomes were any inpatient admission; any ED visit (place of service 23, revenue code 0450 or CPT 99281-99285); the number of outpatient E/M visits (office, telehealth and preventive, counted once per day); and obesity-related outpatient visits (E66 or Z68 on the claim). Costs were the sums of allowed amounts for medical claims, for pharmacy claims (all drugs) and for both combined over days 0-364. Routine cancer screening (colonoscopy or screening mammography) served as a negative control outcome.

### Covariates

The adjustment set was taken from the DAGs using dagitty (minimal sufficient set; Supplementary Figures S2 and S3). It comprised age, sex, census region, plan type, index quarter, obesity class (most recent BMI or class code, with unknown as a separate category), 16 comorbidities (hypertension, dyslipidemia, sleep apnea, prediabetes, MASLD, osteoarthritis, depression, anxiety, GERD, ASCVD, heart failure, CKD, PCOS, hypothyroidism, gallbladder disease, pancreatitis), medications (other anti-obesity drugs, metformin, antihypertensives, statins, antidepressants, number of generics), prior bariatric surgery, endocrinologist visit, any inpatient and ED use, outpatient visits and log baseline cost. Mediators (adverse events, weight loss and out-of-pocket cost of the index drug) were not adjusted for.

### Statistical analysis

Stabilized average treatment effect weights were derived from a logistic propensity score model that included all covariates. Balance was assessed with standardized mean differences (target < 0.10). All outcome models were weighted and used robust (HC0 sandwich) variance. Risk differences (linear probability) and risk ratios (log link) were estimated for binary outcomes. Time to discontinuation was analysed with a Cox model and Kaplan-Meier curves, together with restricted mean time on treatment over 365 days. PDC was modelled with linear regression, visit counts with negative binomial models, pharmacy and total costs with gamma GLMs with a log link, and medical costs with a two-part model (logistic and gamma). Confidence intervals for cost and restricted-mean differences were obtained from 500 bootstrap replicates in which the propensity score was re-estimated. Model assumptions were checked with scaled Schoenfeld residuals (Supplementary Figure S1), the modified Park test and Poisson dispersion statistics.

Patients with a missing birth year or sex were excluded; missing region and obesity class were retained as “Unknown” categories. Prespecified subgroup analyses (obesity class, sex, age 18-44 vs 45-64, consumer-directed vs other plans) used weighted models with robust interaction tests. In sensitivity analyses, the persistence gap was varied (30 and 90 days) and switching was allowed (S1-S3); 1:1 propensity score matching replaced weighting (S4); weights were trimmed (S5); a doubly robust outcome model was fitted (S6); metformin users were excluded (S7); the cohort was restricted to patients with a recorded obesity class (S8); and costs were winsorized (S9). E-values were calculated (S10) to give the minimum strength of association, on the risk ratio scale, that an unmeasured confounder would need with both treatment and outcome to explain away the result (VanderWeele & Ding 2017), and the negative control outcome was analysed (S11). Analyses were run in R 4.4.1 (WeightIt, cobalt, MatchIt, survival, sandwich, MASS, marginaleffects, EValue).

### Sample size

With 5,240 eligible patients and 12-month persistence near 60% in the comparator group, the study had approximately 96% power to detect a 5-percentage-point difference (two-sided alpha 0.05).

## Results

### Study population

Of 10,540 patients with a first Zepbound or Wegovy fill in the identification window, 5,240 met all criteria (Figure 1): 2,558 tirzepatide and 2,682 semaglutide initiators. Most exclusions were due to incomplete enrollment (2,442), no obesity diagnosis (977) or prior GLP-1 RA use (832).

![Figure 1. Cohort selection.](06_output/figures/fig1_cohort_flow.png)

### Baseline characteristics

Before weighting, tirzepatide initiators were slightly younger and more often started treatment in 2025. They had more sleep apnea, less ASCVD and heart failure, and fewer baseline outpatient and ED visits than semaglutide initiators (Table 1). Propensity score distributions overlapped across most of their range (Figure 2). After weighting, no standardized mean difference exceeded 0.01 (Figure 3). Weights ranged from 0.57 to 6.53, and the effective sample sizes were 2,376 and 2,558.

**Table 1. Selected baseline characteristics before and after weighting**

| Characteristic | Tirzepatide (n = 2,558) | Semaglutide 2.4 mg (n = 2,682) | SMD unweighted | SMD weighted |
|---|---|---|---|---|
| Age, mean (SD), years | 44.2 (10.4) | 45.5 (10.4) | -0.13 | 0.00 |
| Female, % | 68.6 | 65.7 | 0.06 | 0.01 |
| CDHP plan, % | 22.8 | 24.2 | -0.03 | 0.00 |
| Index in 2024 Q1-Q2, % | 28.3 | 37.7 | -0.12 / -0.13 | 0.00 |
| Index in 2025 Q1-Q2, % | 37.7 | 28.9 | 0.14 / 0.10 | 0.00 |
| Obesity class 3, % | 34.8 | 31.4 | 0.07 | 0.00 |
| Obesity class unknown, % | 21.0 | 23.5 | -0.06 | 0.00 |
| Hypertension, % | 40.7 | 41.1 | -0.01 | 0.00 |
| Dyslipidemia, % | 34.4 | 37.6 | -0.07 | 0.00 |
| Obstructive sleep apnea, % | 36.0 | 32.1 | 0.08 | 0.00 |
| Prediabetes, % | 23.9 | 22.9 | 0.02 | 0.00 |
| ASCVD, % | 3.3 | 6.4 | -0.15 | 0.00 |
| Heart failure, % | 1.9 | 3.4 | -0.09 | 0.01 |
| Depression, % | 21.2 | 21.1 | 0.00 | 0.00 |
| Metformin, % | 4.5 | 4.6 | -0.01 | 0.00 |
| Endocrinologist visit, % | 39.2 | 41.4 | -0.04 | 0.00 |
| Any ED visit, % | 16.3 | 20.7 | -0.11 | 0.00 |
| Outpatient visits, mean (SD) | 5.5 (3.7) | 6.4 (4.3) | -0.23 | 0.01 |
| Total baseline cost, mean $ | 5,245 | 4,952 | log scale -0.17 | 0.00 |

Full Table 1 (all 34 covariates, weighted and unweighted): `06_output/tables/table1_baseline.csv`.

![Figure 2. Propensity score distributions by treatment group.](06_output/figures/fig2_ps_overlap.png)

![Figure 3. Covariate balance (absolute standardized mean differences) before and after weighting.](06_output/figures/fig3_love_plot.png)

### Persistence, adherence and switching

At 12 months, 58.0% of tirzepatide initiators and 50.8% of semaglutide initiators remained on treatment (risk difference 7.1 percentage points, 95% CI 4.3-9.9; risk ratio 1.14, 1.08-1.20; Table 2). The Kaplan-Meier curves separated from the second month onward (Figure 4). The hazard ratio for discontinuation was 0.81 (0.75-0.88), and the test for non-proportional hazards was not significant (p = 0.41; Supplementary Figure S1). Over the year, tirzepatide initiators spent 16.5 more days on treatment (266 vs 250; 95% CI 9.2-24.0). PDC and the proportion adherent were higher with tirzepatide, and switching to the other drug was much less common (2.2% vs 8.9%).

**Table 2. Persistence, adherence and switching at 12 months (IPTW)**

| Outcome | Tirzepatide | Semaglutide 2.4 mg | Difference (95% CI) | Ratio (95% CI) |
|---|---|---|---|---|
| Persistent at 12 months, % | 58.0 | 50.8 | 7.1 (4.3, 9.9) | RR 1.14 (1.08, 1.20) |
| Discontinuation |  |  |  | HR 0.81 (0.75, 0.88) |
| Restricted mean days on treatment | 266.2 | 249.7 | 16.5 (9.2, 24.0) |  |
| PDC, mean % | 64.1 | 60.3 | 3.8 (2.2, 5.4) |  |
| Adherent (PDC >= 80%), % | 45.9 | 40.5 | 5.4 (2.6, 8.1) | RR 1.13 (1.06, 1.21) |
| Switched to the other drug, % | 2.2 | 8.9 | -6.7 (-8.0, -5.5) | RR 0.25 (0.18, 0.33) |

![Figure 4. Time to discontinuation, IPTW-weighted Kaplan-Meier curves with 95% confidence bands.](06_output/figures/fig4_km_discontinuation.png)

### Healthcare utilization and costs

Inpatient admissions, ED visits and outpatient visits were similar between groups (Table 3), as were mean medical costs. Pharmacy costs were $1,794 lower with tirzepatide (95% CI -$2,055 to -$1,530), and almost all of this difference came from the study drug itself ($9,308 vs $11,102). Total 12-month allowed costs were $1,702 lower with tirzepatide (95% CI -$3,033 to -$371; cost ratio 0.89, 0.81-0.98). Cost distributions were highly skewed (Figure 5).

**Table 3. Healthcare utilization and costs over 12 months (IPTW)**

| Outcome | Tirzepatide | Semaglutide 2.4 mg | Difference (95% CI) | Ratio (95% CI) |
|---|---|---|---|---|
| Any inpatient admission, % | 4.2 | 4.7 | -0.5 (-1.7, 0.6) | RR 0.89 (0.68, 1.15) |
| Any ED visit, % | 23.2 | 24.6 | -1.4 (-3.8, 1.0) | RR 0.94 (0.85, 1.04) |
| Outpatient visits, mean | 5.62 | 5.82 | -0.19 | RR 0.97 (0.92, 1.01) |
| Obesity-related outpatient visits, mean | 3.38 | 3.52 | -0.14 | RR 0.96 (0.91, 1.01) |
| Medical cost, mean $ | 4,420 | 4,327 | 92 (-1,323, 1,395) | 1.02 |
| Pharmacy cost, mean $ | 9,403 | 11,197 | -1,794 (-2,055, -1,530) | 0.84 (0.82, 0.86) |
| Total cost, mean $ | 13,822 | 15,524 | -1,702 (-3,033, -371) | 0.89 (0.81, 0.98) |

Overdispersion (Poisson dispersion 2.5-3.0) supported the use of negative binomial models. The modified Park test (slope 3.58) pointed to a variance function heavier than gamma. As pre-specified, inverse Gaussian and log-normal (smearing) models were therefore fitted; both gave the same total-cost ratio (0.890), and the bootstrap intervals do not depend on this choice.

![Figure 5. Distribution of 12-month medical, pharmacy and total allowed costs by drug (IPTW-weighted, log scale).](06_output/figures/fig5_cost_distributions.png)

### Subgroup and sensitivity analyses

The persistence benefit was similar across subgroups (Figure 6; all interaction p >= 0.29), with risk ratios from 1.06 (obesity class 2) to 1.20 (class 3). Risk ratios in the sensitivity analyses ranged from 1.07 to 1.15 (Table 4; Figure 7). The smallest effect occurred when switching was allowed (S3), because many semaglutide “discontinuers” had switched to tirzepatide. When costs were winsorized at the 99th percentile, the total cost difference widened to -$1,936. The negative control outcome showed no association (RR 0.94, 0.75-1.17). To explain away the primary result, an unmeasured confounder would need to be associated with both drug choice and persistence by a risk ratio of 1.54 (1.38 for the confidence limit; VanderWeele & Ding 2017).

**Table 4. Sensitivity analyses for 12-month persistence**

| Analysis | N | Risk difference, points (95% CI) | Risk ratio (95% CI) |
|---|---|---|---|
| Primary: IPTW, 60-day gap | 5,240 | 7.1 (4.3, 9.9) | 1.14 (1.08, 1.20) |
| S1: 30-day gap | 5,240 | 5.4 (2.7, 8.1) | 1.15 (1.07, 1.23) |
| S2: 90-day gap | 5,240 | 7.4 (4.6, 10.1) | 1.14 (1.08, 1.19) |
| S3: Either drug (switching allowed) | 5,240 | 3.9 (1.2, 6.7) | 1.07 (1.02, 1.12) |
| S4: 1:1 PS matching (ATT) | 4,708 | 6.7 (3.9, 9.6) | 1.13 (1.07, 1.19) |
| S5: Weights trimmed (1st/99th percentile) | 5,240 | 7.0 (4.2, 9.7) | 1.14 (1.08, 1.20) |
| S6: Doubly robust | 5,240 | 7.1 (4.4, 9.8) | 1.14 (1.08, 1.20) |
| S7: Excluding metformin users | 5,001 | 6.5 (3.7, 9.3) | 1.13 (1.07, 1.19) |
| S8: Recorded obesity class only | 4,072 | 7.2 (4.0, 10.3) | 1.14 (1.08, 1.21) |
| S11: Negative control (cancer screening) | 5,240 | -0.4 (-1.9, 1.1) | 0.94 (0.75, 1.17) |

![Figure 6. Persistence by prespecified subgroup.](06_output/figures/fig6_subgroups.png)

![Figure 7. Sensitivity analyses.](06_output/figures/fig7_sensitivity.png)

## Discussion

In this emulated trial of commercially insured adults with obesity, initiation of tirzepatide rather than semaglutide 2.4 mg was associated with 7 more persistent patients per 100 at one year, or about one additional persistent patient for every 14 treated. Tirzepatide initiators also spent 16 more days on treatment, were more adherent and switched far less often. Medical utilization and costs did not differ. Total allowed costs were about $1,700 lower with tirzepatide because its allowed price per fill was lower in these data. The hypotheses were supported, and the estimates changed little across persistence definitions, analytic methods, weight trimming, outlier handling and restriction to patients with a recorded BMI.

The persistence difference lies between the unadjusted estimate from U.S. commercial claims (about 6 points in early 2024; Marshall 2026) and the adjusted estimate from the military cohort (11 points; HR 0.67; Miller 2026), and is smaller than the 15-point difference reported in type 2 diabetes (Hoog 2026). The unadjusted commercial figures are themselves inconsistent: in the full 2024 Prime cohort, one-year persistence was nearly identical for the two drugs (62.6% vs 62.7%; Prime Therapeutics 2025). Comparisons that adjust for confounding and apply a common definition and time window are needed to settle these differences. A smaller relative effect than in the military cohort would be expected where patients face cost sharing, which lowers persistence on both drugs; persistence was much higher when the drugs were provided at no cost (Samuels 2025). Persistence on either drug in this study (51-58%) was close to the roughly 60% reported for recent U.S. commercial initiators.

Greater weight loss with tirzepatide, seen in the trial (Aronne 2025) and in real-world cohorts (Rodriguez 2024; Ng 2025; Cetiner 2026; Richards 2025), is one plausible reason for the higher persistence, since patients who see early results may be more likely to continue. Tolerability is a less likely explanation, as rates of adverse events and of adverse-event-related discontinuation were similar for the two drugs (Hepşen 2026). The similar hospital and ED use agrees with the one previous study that reported these outcomes (Qadeer 2026); 12 months is probably too short for weight-related medical savings to appear.

For payers, persistence and price cannot be judged separately. A drug that keeps more patients on treatment increases pharmacy spending per patient unless its unit price is lower. In these simulated data the more persistent drug was also cheaper per fill, so it provided more treatment-days at a lower total allowed cost, a dominant result over 12 months. With real prices, the conclusion would depend on net prices after rebates, which claims do not show (ICER’s assumed net prices are about $6,800 per year for semaglutide and $8,000 for tirzepatide). Economic models that assume equal treatment duration for the two drugs would misstate their relative value, and persistence estimates such as these can be used for the discontinuation inputs that drive those models (Hwang 2025).

### Strengths

Strengths include a pre-specified, time-stamped SAP; an active-comparator new-user design with aligned time zero; confounder selection based on DAGs; close covariate balance after weighting; complete 12-month follow-up for all patients; payer-relevant outcomes measured from dispensing records and allowed amounts; and a wide set of sensitivity and bias analyses, including a negative control outcome and E-values.

### Limitations

First, the data are synthetic, so the results show how the methods perform, not how the drugs compare. Second, as in any observational study, unmeasured confounding (patient preference, socioeconomic status, prescriber habits, actual BMI) may remain, although the negative control outcome showed no association and the E-value indicates that only a moderately strong unmeasured confounder could explain the result (VanderWeele & Ding 2017). Third, cash-pay and manufacturer direct purchases (for example, self-pay vials) do not appear in claims. Patients who moved to cash pay would be misclassified as discontinuers, and unequal use of such programs could bias the comparison. Fourth, refill-based persistence assumes that dispensed drug was taken, and with a 60-day gap, discontinuations after about day 303 cannot be observed. Fifth, the requirement for 12 months of post-index enrollment excludes people who left the plan and may limit generalizability. Sixth, obesity class was not recorded for about 22% of patients, although restricting the analysis to those with a recorded class did not change the results. Seventh, allowed amounts exclude rebates, so pharmacy and total costs overstate net payer costs. Finally, the study estimates the effect of initiating each drug (an intention-to-treat analogue), not the effect of taking it continuously.

## Conclusions

In simulated commercial claims, initiation of tirzepatide was associated with higher 12-month persistence and adherence than semaglutide 2.4 mg, similar medical utilization and costs, and lower total allowed costs driven by pharmacy prices. The same pre-specified target trial emulation can be run on real claims to estimate the persistence and cost inputs on which the value of anti-obesity medications depends. The next steps are to apply it to real data with net prices, to link claims to clinical measures such as weight, and to extend follow-up beyond one year.

## Declarations

**Data and code availability.** All code (numbered R scripts and an annotated R Markdown file), the protocol and SAP, DAGs, tables and figures are available in the project GitHub repository (github.com/mkNyarko/tirzepatide_heor_synthetic2). The synthetic raw extract is included, and all derived datasets can be rebuilt from it.

**Ethics.** The data are fully synthetic and contain no information on real people, so IRB review was not required.

**Funding and conflicts of interest.** None.

## References

1. Aronne LJ, Horn DB, le Roux CW, et al. Tirzepatide as compared with semaglutide for the treatment of obesity (SURMOUNT-5). N Engl J Med. 2025. doi:10.1056/NEJMoa2416394. Results also posted at ClinicalTrials.gov, NCT05822830.

2. Aronne LJ, et al. Continued treatment with tirzepatide for maintenance of weight reduction in adults with obesity: the SURMOUNT-4 randomized clinical trial. JAMA. 2024. doi:10.1001/jama.2023.24945

3. Cetiner S, et al. Real-world effectiveness and safety of tirzepatide, semaglutide, and liraglutide in adults with overweight or obesity without diabetes: a comparative study. Diabetes Metab Syndr Obes. 2026;19:594898. doi:10.2147/DMSO.S594898

4. Gasoyan H, et al. Changes in weight and glycemic control following obesity treatment with semaglutide or tirzepatide by discontinuation status. Obesity (Silver Spring). 2025;33:1657-1667. doi:10.1002/oby.24331

5. Hepşen S, et al. Real-world comparison of short-term adverse events, treatment persistence, and efficacy of semaglutide and tirzepatide: a nationwide multicenter study. Obes Facts. 2026. doi:10.1159/000552104

6. Hernán MA, Robins JM. Using big data to emulate a target trial when a randomized trial is not available. Am J Epidemiol. 2016;183(8):758-764.

7. Hoog MM, et al. Real-world treatment patterns and cost per patient achieving treatment targets among tirzepatide and semaglutide initiators in US patients with type 2 diabetes. J Manag Care Spec Pharm. 2026;32(10):1173-1188. doi:10.18553/jmcp.2026.32.10.1173

8. Hwang et al. Lifetime health effects and cost-effectiveness of tirzepatide and semaglutide in US adults. JAMA Health Forum. 2025. PMID 40085108

9. Institute for Clinical and Economic Review (ICER). Obesity Management: Final Evidence Report, and Report at a Glance. December 2025.

10. Langan SM, et al. The reporting of studies conducted using observational routinely collected health data statement for pharmacoepidemiology (RECORD-PE). BMJ. 2018;363:k3532.

11. Marshall LZ, et al. Trends in 1-year persistence and adherence among initiators of high-potency, weight loss-indicated glucagon-like peptide 1 receptor agonists. J Manag Care Spec Pharm. 2026;32(3):281-291. doi:10.18553/jmcp.2026.32.3.281

12. Miller LB, et al. Patterns of use for GLP-1 receptor agonists in a weight management cohort: a Military Health System database analysis of active duty service members from 2021 to 2025. Mil Med. 2026. doi:10.1093/milmed/usag316

13. Ng CD, et al. Real-world weight loss observed with semaglutide and tirzepatide in patients with overweight or obesity and without type 2 diabetes (SHAPE). Adv Ther. 2025;42(11):5468-5480.

14. Prime Therapeutics. GLP-1 therapy to treat obesity among members without diabetes: three-year persistence and year-over-year persistence rate change. Research abstract, June 25, 2025.

15. Qadeer A, et al. Comparative real-world outcomes of tirzepatide vs semaglutide in patients with obesity and type 2 diabetes: a retrospective propensity-matched cohort study. Diab Vasc Dis Res. 2026;23(3). doi:10.1177/14791641261465360

16. Richards R, et al. Semaglutide and tirzepatide in a remote weight management program: 12-month retrospective observational study. JMIR Form Res. 2025;9:e81912. doi:10.2196/81912

17. Rodriguez PJ, et al. Semaglutide vs tirzepatide for weight loss in adults with overweight or obesity. JAMA Intern Med. 2024;184(9):1056-1064.

18. Samuels JM, et al. Real-world titration, persistence and weight loss of semaglutide and tirzepatide in an academic obesity clinic. Diabetes Obes Metab. 2025;27(11):6200-6209. doi:10.1111/dom.70004

19. VanderWeele TJ, Ding P. Sensitivity analysis in observational research: introducing the E-value. Ann Intern Med. 2017;167(4):268-274. doi:10.7326/M16-2607

## Supplementary Figures

![Supplementary Figure S1. Scaled Schoenfeld residuals for treatment in the Cox model for discontinuation.](06_output/figures/figS1_schoenfeld.png)

![Supplementary Figure S2. Directed acyclic graph for 12-month persistence.](06_output/figures/fig0_dag_persistence.png)

![Supplementary Figure S3. Directed acyclic graph for 12-month costs and utilization.](06_output/figures/fig0_dag_costs.png)
