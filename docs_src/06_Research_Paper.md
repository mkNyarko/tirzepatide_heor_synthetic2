<!-- out: 07_reports/06_Research_Paper.docx -->
# Twelve-Month Persistence, Healthcare Utilization and Costs of Tirzepatide versus Semaglutide 2.4 mg in Commercially Insured Adults with Obesity: A Target Trial Emulation in Synthetic Claims Data

Maxwell K. Nyarko

**Methods demonstration.** All analyses use a fully synthetic claims dataset generated for training. The results describe the simulated data and must not be read as evidence about either drug.

## Abstract

**Objective.** To compare 12-month treatment persistence, adherence, healthcare resource utilization and all-cause costs between new users of tirzepatide (Zepbound) and semaglutide 2.4 mg (Wegovy) among commercially insured adults with obesity and without diabetes.

**Methods.** We emulated a target trial using a synthetic U.S. commercial claims extract (January 2023-June 2026). Adults aged 18-64 with an obesity diagnosis, no diabetes, no GLP-1 receptor agonist use in the prior 365 days, and continuous enrollment for 365 days before and after their first fill (index) between January 2024 and June 2025 were included. Confounding was addressed with stabilized inverse probability of treatment weights from a propensity score including demographics, plan type, calendar quarter, obesity class, comorbidities, medications and baseline utilization and costs. The primary outcome was persistence at 12 months (no refill gap > 60 days). Secondary outcomes were time to discontinuation, proportion of days covered (PDC), switching, inpatient, emergency department (ED) and outpatient use, and medical, pharmacy and total allowed costs.

**Results.** Of 10,540 initiators, 5,240 were eligible (2,558 tirzepatide; 2,682 semaglutide). After weighting, all standardized mean differences were 0.01 or less. Persistence at 12 months was 58.0% with tirzepatide and 50.8% with semaglutide (risk difference 7.1 percentage points, 95% CI 4.3-9.9; risk ratio 1.14, 1.08-1.20); the hazard ratio for discontinuation was 0.81 (0.75-0.88). Tirzepatide initiators had higher PDC (64.1% vs 60.3%) and switched less (2.2% vs 8.9%). Inpatient, ED and outpatient use did not differ meaningfully. Mean 12-month medical costs were similar ($4,420 vs $4,327), while pharmacy ($9,403 vs $11,197) and total costs ($13,822 vs $15,524; difference -$1,702, 95% CI -$3,033 to -$371) were lower with tirzepatide, reflecting a lower allowed amount per fill in these data. Results were consistent across 11 sensitivity analyses; a negative control outcome was null and the E-value was 1.54.

**Conclusions.** In this simulated population, starting tirzepatide rather than semaglutide 2.4 mg was associated with higher 12-month persistence and adherence, no difference in medical utilization, and lower total allowed costs driven by pharmacy prices. The workflow shows how a pre-specified, confounding-adjusted target trial emulation in claims can inform payer decisions and economic models.

\newpage

## Introduction

Tirzepatide, a dual GIP/GLP-1 receptor agonist, produced greater weight loss than semaglutide 2.4 mg in the head-to-head SURMOUNT-5 trial (-20.2% vs -13.7% at 72 weeks). The value of either drug, however, depends on patients staying on treatment: in SURMOUNT-4, stopping tirzepatide led to substantial weight regain, and in routine care more than one in five patients stop within three months, with much smaller weight loss among early discontinuers (Gasoyan 2025).

Real-world comparisons of the two drugs have focused on weight change, often in single clinics or with the diabetes-labeled products. One-year persistence in U.S. commercial claims has been reported only without adjustment for confounding (Marshall 2026), and the only adjusted comparison comes from active-duty military personnel without cost sharing (Miller 2026; HR for discontinuation 0.67). No study has compared all-cause healthcare utilization and costs between the two drugs in adults with obesity without diabetes. Published cost-effectiveness models disagree widely, largely because of differing assumptions about treatment duration and price (ICER 2025; Hwang 2025).

We therefore compared 12-month persistence (primary aim), adherence and switching, healthcare utilization, and all-cause costs from a U.S. commercial payer perspective between new users of tirzepatide and semaglutide 2.4 mg, using a pre-specified target trial emulation. We hypothesized that tirzepatide would have higher persistence and adherence, that medical utilization and costs would differ little, and that total cost differences would be driven by pharmacy costs.

## Methods

### Design

This was a retrospective new-user, active-comparator cohort study framed as the emulation of a target trial (Hernán & Robins 2016). The protocol and statistical analysis plan (SAP), including the directed acyclic graphs (DAGs), were committed to a version-controlled repository before any outcome was derived. Reporting follows RECORD-PE and the TARGET guideline.

| Element | Target trial | Emulation |
|---|---|---|
| Eligibility | Adults 18-64, obesity, no diabetes, no prior GLP-1 RA, commercially insured | Diagnosis and pharmacy codes in a 365-day baseline; continuous enrollment |
| Strategies | Start tirzepatide vs start semaglutide 2.4 mg | First fill of Zepbound vs Wegovy |
| Assignment | Random | Inverse probability of treatment weighting on measured confounders |
| Time zero | Randomization | First fill (eligibility, assignment and follow-up aligned) |
| Follow-up | 12 months | Index to day 364 |
| Causal contrast | Intention-to-treat | Observational analogue (treatment fixed at index); average treatment effect |

### Data source

We used a synthetic commercial claims extract that mimics vendor databases (Optum, MarketScan): member demographics (birth year, sex, state), enrollment segments with separate medical and pharmacy coverage and plan type, pharmacy claims (NDC, fill date, days supply, quantity, allowed amounts) and medical claims (ICD-10-CM diagnoses, CPT/HCPCS, revenue codes, place of service, allowed amounts) from January 2023 to June 2026. Members had at least one anti-obesity medication or GLP-1 RA fill. Costs are allowed amounts in nominal dollars; rebates and cash-pay purchases are not observed.

### Data management

A data-quality review logged 28 checks before cleaning. NDCs in three formats were normalized to 11 digits; reversed pharmacy claims and the claims they reversed were removed; duplicates were dropped; ICD-10 codes were standardized; implausible days-supply values (0-2, 365, 999 days; n = 935 after cleaning) were replaced with the usual value for the NDC and quantity; missing allowed amounts were imputed from paid amounts; negative adjustment lines were netted within claims. Enrollment segments with both medical and pharmacy coverage were merged into continuous spans, bridging gaps of 30 days or less.

### Study population

The index date was the first Zepbound or Wegovy fill between January 1, 2024 and June 30, 2025. Patients were included if they filled only one study drug on the index date; were aged 18-64; had known sex and no conflicting records; had continuous enrollment from 365 days before to 364 days after index; had no fill of any GLP-1 RA (Zepbound, Wegovy, Mounjaro, Ozempic, Rybelsus, Saxenda) in the 365-day baseline; had an obesity diagnosis (E66 excluding E66.3, or BMI code Z68.30-Z68.45) in baseline or on the index date; had no diabetes (no E10/E11 code and no non-metformin antidiabetic drug); and had no medullary thyroid cancer or MEN 2 code.

### Exposure

Tirzepatide initiators formed the exposed group and semaglutide 2.4 mg initiators the comparator group, fixed at index.

### Outcomes

Persistence was built from fills of the index molecule (tirzepatide: Zepbound or Mounjaro; semaglutide: Wegovy, Ozempic or Rybelsus), with early refills carried forward. Discontinuation was the first gap of more than 60 days without supply, including after the last fill; persistence at 12 months was the absence of discontinuation. Time to discontinuation was measured from index to the first day without supply. Because a gap must exceed 60 days within follow-up, discontinuations are observable only when supply ends by about day 303. PDC was days covered divided by 365; adherence was PDC >= 80%. Switching was any fill of the other molecule. Utilization outcomes were any inpatient admission, any ED visit (place of service 23, revenue code 0450 or CPT 99281-99285), the number of outpatient E/M visits (office, telehealth and preventive; one per day) and obesity-related outpatient visits (E66 or Z68 on the claim). Costs were the sums of allowed amounts for medical claims, pharmacy claims (all drugs) and their total over days 0-364. A negative control outcome was routine cancer screening (colonoscopy or screening mammography).

### Covariates

The adjustment set was derived from DAGs with dagitty (minimal sufficient set): age, sex, census region, plan type, index quarter, obesity class (most recent BMI or class code; unknown as a category), 16 comorbidities (hypertension, dyslipidemia, sleep apnea, prediabetes, MASLD, osteoarthritis, depression, anxiety, GERD, ASCVD, heart failure, CKD, PCOS, hypothyroidism, gallbladder disease, pancreatitis), medications (other anti-obesity drugs, metformin, antihypertensives, statins, antidepressants, number of generics), prior bariatric surgery, endocrinologist visit, any inpatient and ED use, outpatient visits and log baseline cost. Mediators (adverse events, weight loss, out-of-pocket cost of the index drug) were not adjusted for.

### Statistical analysis

A logistic propensity score model including all covariates gave stabilized average treatment effect weights. Balance was assessed with standardized mean differences (target < 0.10). Weighted models with robust (HC0 sandwich) variance estimated risk differences (linear probability) and risk ratios (log link) for binary outcomes; a weighted Cox model and Kaplan-Meier curves for time to discontinuation, with restricted mean time on treatment over 365 days; weighted linear regression for PDC; weighted negative binomial models for visit counts; weighted gamma GLMs with log link for pharmacy and total costs; and a two-part model (logistic and gamma) for medical costs. Confidence intervals for cost and restricted-mean differences came from 500 bootstrap replicates that re-estimated the propensity score. Assumptions were checked with Schoenfeld residuals, the modified Park test and Poisson dispersion.

Missing birth year or sex led to exclusion; missing region and obesity class were kept as "Unknown" categories. Prespecified subgroup analyses (obesity class, sex, age 18-44 vs 45-64, consumer-directed vs other plans) used weighted models with robust interaction tests. Sensitivity analyses varied the persistence gap (30, 90 days) and allowed switching (S1-S3), used 1:1 propensity score matching (S4), trimmed weights (S5), a doubly robust outcome model (S6), excluded metformin users (S7), restricted to patients with a recorded obesity class (S8), winsorized costs (S9), computed E-values (S10) and analysed the negative control outcome (S11). Analyses used R 4.4.1 (WeightIt, cobalt, MatchIt, survival, sandwich, MASS, marginaleffects, EValue).

### Sample size

With 5,240 eligible patients and 12-month persistence near 60% in the comparator group, the study had about 96% power to detect a 5-percentage-point difference (two-sided alpha 0.05).

## Results

### Study population

Of 10,540 patients with a first Zepbound or Wegovy fill in the identification window, 5,240 met all criteria (Figure 1): 2,558 tirzepatide and 2,682 semaglutide initiators. The largest exclusions were for incomplete enrollment (2,442), absence of an obesity diagnosis (977) and prior GLP-1 RA use (832).

![Figure 1. Cohort selection.](06_output/figures/fig1_cohort_flow.png)

### Baseline characteristics

Before weighting, tirzepatide initiators were slightly younger, more often started in 2025, had more sleep apnea and less ASCVD and heart failure, and had fewer baseline outpatient visits and ED visits than semaglutide initiators (Table 1). After weighting, all standardized mean differences were 0.01 or less (Figure 3); weights ranged from 0.57 to 6.53 and the effective sample sizes were 2,376 and 2,558.

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

### Persistence, adherence and switching

At 12 months, 58.0% of tirzepatide and 50.8% of semaglutide initiators remained on treatment (risk difference 7.1 percentage points, 95% CI 4.3-9.9; risk ratio 1.14, 1.08-1.20; Table 2). The curves separated from the second month and stayed apart (Figure 4); the hazard ratio for discontinuation was 0.81 (0.75-0.88), with no evidence against proportional hazards (p = 0.41). Tirzepatide initiators spent 16.5 more days on treatment over the year (266 vs 250; 95% CI 9.2-24.0). PDC and the proportion adherent were higher with tirzepatide, and switching to the other drug was much less common (2.2% vs 8.9%).

**Table 2. Persistence, adherence and switching at 12 months (IPTW)**

| Outcome | Tirzepatide | Semaglutide 2.4 mg | Difference (95% CI) | Ratio (95% CI) |
|---|---|---|---|---|
| Persistent at 12 months, % | 58.0 | 50.8 | 7.1 (4.3, 9.9) | RR 1.14 (1.08, 1.20) |
| Discontinuation | | | | HR 0.81 (0.75, 0.88) |
| Restricted mean days on treatment | 266.2 | 249.7 | 16.5 (9.2, 24.0) | |
| PDC, mean % | 64.1 | 60.3 | 3.8 (2.2, 5.4) | |
| Adherent (PDC >= 80%), % | 45.9 | 40.5 | 5.4 (2.6, 8.1) | RR 1.13 (1.06, 1.21) |
| Switched to the other drug, % | 2.2 | 8.9 | -6.7 (-8.0, -5.5) | RR 0.25 (0.18, 0.33) |

![Figure 4. Time to discontinuation, IPTW-weighted Kaplan-Meier curves with 95% confidence bands.](06_output/figures/fig4_km_discontinuation.png)

### Healthcare utilization and costs

Inpatient admissions, ED visits and outpatient visits were similar between groups (Table 3). Mean medical costs were similar, whereas pharmacy costs were $1,794 lower with tirzepatide (95% CI -$2,055 to -$1,530), almost entirely from the study drug ($9,308 vs $11,102). Total 12-month allowed costs were $1,702 lower with tirzepatide (95% CI -$3,033 to -$371; cost ratio 0.89, 0.81-0.98). Costs were highly skewed (Figure 5).

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

Model checks supported the negative binomial models (Poisson dispersion 2.5-3.0). The modified Park test (slope 3.58) suggested a variance function heavier than gamma; as pre-specified, inverse Gaussian and log-normal (smearing) models were fitted and gave the same total-cost ratio (0.890), and the bootstrap intervals do not depend on this choice.

### Subgroup and sensitivity analyses

The persistence benefit was consistent across subgroups (Figure 6; all interaction p >= 0.29), with risk ratios from 1.06 (obesity class 2) to 1.20 (class 3). Every sensitivity analysis gave a risk ratio between 1.07 and 1.15 (Table 4; Figure 7). The smallest effect was seen when switching was allowed (S3), because many semaglutide "discontinuers" had switched to tirzepatide. Winsorizing costs at the 99th percentile increased the total cost difference to -$1,936. The negative control outcome was null (RR 0.94, 0.75-1.17). An unmeasured confounder would need to be associated with both drug choice and persistence by a risk ratio of 1.54 (1.38 for the confidence limit) to explain away the primary result.

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

In this emulated trial of commercially insured adults with obesity, starting tirzepatide rather than semaglutide 2.4 mg was associated with 7 more persistent patients per 100 at one year (about one additional persistent patient for every 14 treated), 16 more days on treatment, higher adherence and far less switching. Medical utilization and costs did not differ, and total allowed costs were about $1,700 lower with tirzepatide because its allowed price per fill was lower in these data. All hypotheses were supported, and the findings were robust to the persistence definition, analytic method, weight trimming, outliers and missing BMI.

The size of the persistence difference falls between the unadjusted estimate from U.S. commercial claims (about 6 points in early 2024; Marshall 2026) and the adjusted military estimate (11 points; HR 0.67; Miller 2026). A smaller relative effect than in the military cohort is plausible where patients face cost sharing, which lowers persistence on both drugs. Persistence on either drug was in the range reported for recent U.S. commercial initiators (51-58% vs about 60%). Similar hospital and ED use agrees with the one prior study reporting these outcomes (Qadeer 2026), and 12 months is probably too short for weight-related medical savings to appear.

For payers, the results illustrate that persistence and price act together: a drug that keeps more patients on treatment raises pharmacy spending per patient unless its unit price is lower. In these simulated data the more persistent drug was also cheaper per fill, so it delivered more treatment-days at a lower total allowed cost, a dominant result over 12 months. With real prices, the conclusion depends on net prices after rebates, which claims do not show (ICER's assumed net prices are about $6,800 for semaglutide and $8,000 for tirzepatide per year). Economic models that assume equal treatment duration for the two drugs would misstate their relative value; persistence estimates of this kind can inform the discontinuation inputs that drive those models (Hwang 2025).

### Strengths

The study used a pre-specified, time-stamped SAP; an active-comparator new-user design with aligned time zero; DAG-based confounder selection; excellent covariate balance; full 12-month follow-up for all patients; payer-relevant outcomes measured from dispensing and allowed amounts; and a broad set of sensitivity and bias analyses, including a negative control outcome and E-values.

### Limitations

First, the data are synthetic; the results show how the methods work and not how the drugs compare. Second, as in any observational study, unmeasured confounding (patient preference, socioeconomic status, prescriber habits, actual BMI) may remain, although the negative control was null and the E-value suggests moderate robustness. Third, cash-pay and manufacturer direct purchases (e.g., self-pay vials) do not appear in claims; patients who moved to cash pay would be misclassified as discontinuers, and differential use of such programs could bias the comparison. Fourth, refill-based persistence assumes that dispensed drug was taken, and with a 60-day gap discontinuations after about day 303 cannot be observed. Fifth, requiring 12 months of post-index enrollment excludes people who left the plan and may limit generalizability. Sixth, obesity class was unrecorded for about 22% of patients; restricting to those with a recorded class did not change the results. Seventh, allowed amounts exclude rebates, so pharmacy and total costs overstate payer net costs. Finally, the study measures the effect of initiating each drug (intention-to-treat analogue), not of taking it continuously.

## Conclusions

In simulated commercial claims, tirzepatide initiation was associated with higher 12-month persistence and adherence than semaglutide 2.4 mg, similar medical utilization and costs, and lower total allowed costs driven by pharmacy prices. The study demonstrates a reproducible, pre-specified target trial emulation workflow that payers and modelers could apply to real claims to estimate the persistence and cost inputs that drive the value of anti-obesity medications. Future work should use real data with net prices, link claims to clinical measures such as weight, and extend follow-up beyond one year.

## Declarations

**Data and code availability.** All code (numbered R scripts and an annotated R Markdown file), the protocol and SAP, DAGs, tables and figures are in the project GitHub repository (github.com/mkNyarko/tirzepatide_heor_synthetic2). The synthetic raw extract is included; derived datasets can be rebuilt from it.

**Ethics.** The data are fully synthetic and contain no information on real people; IRB review was not required.

**Funding and conflicts of interest.** None.

## References

1. Aronne LJ, et al. Tirzepatide as compared with semaglutide for the treatment of obesity (SURMOUNT-5). N Engl J Med. 2025. doi:10.1056/NEJMoa2416394
2. Aronne LJ, et al. Continued treatment with tirzepatide for maintenance of weight reduction in adults with obesity: the SURMOUNT-4 randomized clinical trial. JAMA. 2024. doi:10.1001/jama.2023.24945
3. Gasoyan H, et al. Changes in weight and glycemic control following obesity treatment with semaglutide or tirzepatide by discontinuation status. Obesity. 2025;33:1657-1667.
4. Marshall LZ, et al. Trends in 1-year persistence and adherence among initiators of high-potency, weight loss-indicated GLP-1 RAs. J Manag Care Spec Pharm. 2026;32(3):281-291.
5. Miller LB, et al. Patterns of use for GLP-1 receptor agonists in a weight management cohort: a Military Health System database analysis of active duty service members from 2021 to 2025. Mil Med. 2026. doi:10.1093/milmed/usag316
6. Qadeer A, et al. Comparative real-world outcomes of tirzepatide vs semaglutide in patients with obesity and type 2 diabetes. Diab Vasc Dis Res. 2026;23(3).
7. Hoog MM, et al. Real-world treatment patterns and cost per patient achieving treatment targets among tirzepatide and semaglutide initiators in US patients with type 2 diabetes. J Manag Care Spec Pharm. 2026;32(10):1173-1188.
8. Institute for Clinical and Economic Review. Obesity Management: Final Evidence Report. December 2025.
9. Hwang et al. Lifetime health effects and cost-effectiveness of tirzepatide and semaglutide in US adults. JAMA Health Forum. 2025.
10. Hernán MA, Robins JM. Using big data to emulate a target trial when a randomized trial is not available. Am J Epidemiol. 2016;183(8):758-764.
11. Langan SM, et al. The reporting of studies conducted using observational routinely collected health data statement for pharmacoepidemiology (RECORD-PE). BMJ. 2018;363:k3532.
12. VanderWeele TJ, Ding P. Sensitivity analysis in observational research: introducing the E-value. Ann Intern Med. 2017;167(4):268-274.
