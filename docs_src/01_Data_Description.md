<!-- out: 01_protocol/01_Data_Description.docx -->
# Data Description

**Synthetic commercial claims extract used for the tirzepatide vs semaglutide 2.4 mg study**

Maxwell K. Nyarko | October 7, 2026

The dataset is fully synthetic. It contains no real patients and was generated with known relationships so that the analytic methods can be checked. It copies the structure, coding systems and common flaws of commercial claims databases such as Optum Clinformatics or Merative MarketScan.

## 1. Why claims data were chosen for this research question

The research question is about what happens in routine care when commercially insured adults start tirzepatide or semaglutide 2.4 mg: do they stay on treatment, and what do they cost the payer? Administrative claims fit this question better than the other main real-world data sources.

| Need of the research question | Why claims meet it | Alternative sources and their gap |
|---|---|---|
| Persistence and adherence measured objectively | Every pharmacy fill is recorded with fill date, days supply and quantity, so refill gaps, PDC and switching can be built from dispensing (not prescribing) | EHRs record prescriptions written, not whether they were filled; surveys rely on self-report |
| All-cause utilization and costs from the payer perspective | Claims carry the allowed amount for every medical and pharmacy service paid by the plan, across all providers | EHRs capture only one health system's encounters and no payments |
| Complete capture during follow-up | Enrollment files show when a person is covered, so absence of a claim means no billed care during covered time | EHRs miss care received outside the system (leakage) |
| Population of interest (commercially insured adults 18-64) | Commercial claims databases cover tens of millions of employer-insured members | Medicare data cover older adults; trials enroll selected volunteers |
| New-user, active-comparator design | Long look-back allows a washout for prior GLP-1 RA use and baseline confounders | Registries rarely include both drugs with a common baseline |
| Sample size | Thousands of initiators of each drug within 18 months | Single-clinic studies in the literature had a few hundred to a few thousand patients |

Known trade-offs, which shaped the design: claims lack clinical values (BMI, weight change, HbA1c), lab results and the reason for stopping a drug; diagnoses are recorded for billing and may be incomplete; and drugs bought outside the benefit (manufacturer cash-pay programs such as LillyDirect or NovoCare, or with coupons) are invisible. The study therefore focuses on outcomes that claims measure well (fills, utilization and payer costs) rather than weight loss.

## 2. Features that make this a claims dataset

| Feature | What it looks like in this extract | Why it is typical of claims |
|---|---|---|
| Member-level linkage | One de-identified `member_id` links all tables | Vendors replace identifiers with study IDs |
| De-identified demographics | Birth year only (no birth date), sex, state | HIPAA de-identification limits dates and geography |
| Eligibility (enrollment) file | Segments with start and end dates, plan type, employer group, and separate medical and pharmacy coverage flags | Needed to know when a person's care would appear in the data; pharmacy claims are captured only with drug coverage |
| Pharmacy claims (NCPDP) | One row per dispensing transaction: NDC, fill date, days supply, metric quantity, refill number, channel (retail, mail, specialty), allowed, paid and out-of-pocket amounts | Standard retail pharmacy transaction fields |
| Reversals | Reversed transactions (`claim_status = R`) carry the same claim ID with negative amounts | Pharmacies reverse claims that are never picked up or are re-billed |
| Medical claims (CMS-1500 and UB-04) | Professional (PROF) and institutional (INST) claims, one row per line, with CPT/HCPCS procedure codes, revenue codes, place of service, provider specialty, admission and discharge dates | Professional and facility billing formats |
| Diagnosis coding | Up to 5 ICD-10-CM codes per claim, repeated on every line | Billing forms carry header-level diagnoses |
| Coding systems | NDC-11, ICD-10-CM, CPT/HCPCS, UB-04 revenue codes, CMS place-of-service codes | Standard U.S. code sets |
| Costs | Allowed and paid amounts in nominal dollars; no rebates | Claims show what the plan allowed and paid; manufacturer rebates are paid later and are not in claims |
| Calendar-year files | Claims split into yearly gzip files | Typical vendor delivery |
| Selection of members | Members selected for at least one anti-obesity or GLP-1 RA fill | Vendors deliver study-specific extracts |
| Right censoring | Data end June 30, 2026; enrollment segments are cut at that date | Every extract has a data cut-off |

## 3. Size and content of the extract

| Table | Rows | Key content |
|---|---|---|
| members.csv | 14,766 (14,700 unique members) | birth year, sex (F 9,608; M 5,096; U 62), state |
| enrollment.csv | 94,388 segments | 2018-2026 coverage; plan types PPO 39%, CDHP 24%, HMO 16%, POS 13%, EPO 9% |
| pharmacy_claims 2023-2026 | 553,699 transactions | all drugs; 10,535 reversals; 51 NDCs in the lookup |
| medical_claims 2023-2026 | 646,831 claim lines | 607,210 professional and 39,621 institutional lines |
| Reference tables | 8 files | NDC lookup, ICD-10-CM, CPT/HCPCS, place of service, revenue codes, provider specialty, state-to-region, data dictionary |

Extract period: January 1, 2023 to June 30, 2026. Study drugs: Zepbound (tirzepatide; 6 NDCs, 2.5-15 mg pens) and Wegovy (semaglutide 2.4 mg; 5 NDCs, 0.25-2.4 mg pens). Diabetes-labeled products (Mounjaro, Ozempic, Rybelsus), liraglutide (Saxenda), other anti-obesity drugs and common chronic medications are also present.

## 4. Data quality problems found (and how they were handled)

Like a real vendor extract, the files contain errors that must be found and fixed before analysis. All were logged by `05_code/02_data_quality_review.R` (`06_output/tables/data_quality_log.csv`).

| Table | Problem | Rows affected | Handling |
|---|---|---|---|
| members | Exact duplicate rows | 44 | Dropped |
| members | Same ID with conflicting demographics (e.g., sex differs) | 22 IDs | Members excluded |
| members | Missing birth year | 23 | Excluded at the age criterion |
| members | Sex unknown (U) | 62 | Excluded |
| members | Missing state | 49 | Region = Unknown |
| enrollment | Exact duplicate segments | 470 | Dropped |
| enrollment | Overlapping segments | 1,986 | Merged into continuous spans |
| enrollment | Gaps between segments | 1,114 | Gaps of 30 days or less bridged |
| enrollment | No pharmacy coverage in segment | 252 | Not counted as covered time |
| pharmacy | NDC with hyphens (5-4-2) | 127,841 | Hyphens removed |
| pharmacy | NDC in 4-4-2 format | 21,683 | Labeler padded to 5 digits |
| pharmacy | NDC stored as a number (leading zeros lost) | 9,379 | Left-padded to 11 digits |
| pharmacy | Exact duplicate rows | 2,964 | Dropped |
| pharmacy | Reversed claims | 10,535 | Reversal and the reversed paid claim both dropped |
| pharmacy | Same paid claim ID repeated with format-only differences | 2,310 | One row kept |
| pharmacy | Missing allowed amount | 1,582 | Imputed as paid + out-of-pocket |
| pharmacy | Implausible days supply (0, 1, 2, 365, 999) | 961 | Replaced with the usual days supply for the NDC and quantity |
| medical | Exact duplicate lines | 2,706 | Dropped |
| medical | Lower-case ICD-10 codes | 49,863 | Upper-cased |
| medical | ICD-10 codes with and without decimal point | 216,122 with a dot | Dots removed |
| medical | Place of service "2" instead of "02" | 649 | Left-padded |
| medical | Duplicate claim lines differing only in code format | 2,402 | One row kept |
| medical | Missing allowed amount | 1,916 | Imputed from paid using the typical paid-to-allowed ratio |
| medical | Negative adjustment lines | 3,193 | Kept and netted within claim; claim totals floored at $0 |
| medical | Very large inpatient lines (> $100,000) | 147 | Kept; winsorized in a sensitivity analysis |

## 5. Limitations of the data for this question

- No clinical measurements (BMI value, weight, HbA1c); obesity severity comes only from optional BMI Z-codes.
- No information on why a drug was stopped (side effects, cost, supply shortage, goal reached).
- Cash-pay and manufacturer direct-to-consumer purchases are not captured; these are common for anti-obesity drugs and would look like discontinuation.
- Allowed amounts exclude manufacturer rebates, which are large for both drugs, so pharmacy costs are higher than the payer's true net cost.
- Requiring 12 months of continuous enrollment after index excludes people who leave the plan.
- Because the data are synthetic, results show how the methods work and say nothing about the real drugs.
