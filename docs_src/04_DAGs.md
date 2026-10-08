<!-- out: 01_protocol/04_Directed_Acyclic_Graphs.docx -->
# Directed Acyclic Graphs (DAGs)

**Tirzepatide vs semaglutide 2.4 mg: persistence, utilization and costs in commercially insured adults with obesity (synthetic claims)**

Maxwell K. Nyarko | Version 1.0 | October 7, 2026 | Prepared with the SAP, before outcome analysis

## 1. Purpose

A directed acyclic graph (DAG) writes down what we assume causes what. Each arrow means "may directly affect". From the DAG we can work out which baseline variables must be adjusted for to remove confounding of the drug-outcome relationship (the adjustment set), and which variables must not be adjusted for because they lie on the causal pathway (mediators) or would open a biased path (colliders). The DAGs were drawn from the literature review (Section 4) and coded in R with the dagitty package (05_code/00b_dag.R), which also derived the minimal adjustment sets.

## 2. DAG 1: drug choice and 12-month persistence

![DAG 1. Assumed causal structure for tirzepatide vs semaglutide 2.4 mg and 12-month persistence. Green = measured confounders (adjusted); red = mediators (not adjusted); grey = unmeasured; blue = exposure; orange = outcome.](06_output/figures/fig0_dag_persistence.png)

## 3. DAG 2: drug choice and 12-month utilization and costs

![DAG 2. Assumed causal structure for costs and utilization. Persistence is a mediator here: the drug affects costs partly through how long patients stay on (and pay for) treatment.](06_output/figures/fig0_dag_costs.png)

## 4. Nodes and the reasoning behind the arrows

| Node | Role | Claims measure | Why it is in the DAG |
|---|---|---|---|
| Drug | Exposure | Index fill: Zepbound vs Wegovy | Treatment being compared |
| Persistence / Costs | Outcomes | Refill gaps; allowed amounts | Study outcomes |
| Age | Confounder | Index year - birth year | Prescribers' choice may differ by age; older patients have more comorbidity, cost and different persistence (Marshall 2026; Miller 2026) |
| Sex | Confounder | Member sex | Women are the majority of users; men had higher discontinuation (Miller 2026 HR 1.12) |
| Region | Confounder | Census region from state | Regional prescribing and formulary patterns; regional cost levels |
| Plan type | Confounder | PPO/HMO/POS/EPO/CDHP at index | Benefit design drives formulary coverage (drug choice) and cost sharing (persistence); CDHP members face deductibles |
| Calendar time | Confounder | Index quarter | Wegovy shortages in 2023-2024, Zepbound launch (Nov 2023), new indications (Wegovy cardiovascular risk reduction, March 2024; Zepbound sleep apnea, December 2024), coverage changes; persistence improved over time (Marshall 2026) |
| Obesity severity | Confounder | Obesity class from BMI/E66.81x codes | Higher BMI may favor the more potent drug and changes motivation and benefit |
| Comorbidity | Confounder | Hypertension, dyslipidemia, sleep apnea, prediabetes, MASLD, osteoarthritis, depression, anxiety, GERD, ASCVD, HF, CKD, PCOS, hypothyroidism, gallbladder disease, pancreatitis | Indications differ by comorbidity (ASCVD -> Wegovy; sleep apnea -> Zepbound); comorbidity drives costs and utilization; GI history may affect tolerance |
| Prior anti-obesity medication | Confounder | Phentermine, naltrexone-bupropion fills | Treatment history shapes drug choice and expectations |
| Baseline utilization / costs | Confounder (proxy for health status and care-seeking) | Inpatient, ED, outpatient visits; log total allowed cost; number of generics | Sicker or more engaged patients may be steered to one drug and have different future costs |
| Endocrinologist care | Confounder | Endocrinology visit in baseline | Specialists may prefer one drug and provide more support for persistence |
| GI adverse events | Mediator | Not adjusted | Caused by the drug; causes discontinuation |
| Weight loss | Mediator | Not measured in claims | Caused by the drug; early success may keep patients on treatment |
| Out-of-pocket cost of the index drug | Mediator | Not adjusted | Determined by which drug is chosen (formulary tier); affects persistence |
| Persistence (in DAG 2) | Mediator for costs | Not adjusted | Staying on the drug adds pharmacy cost and may change medical cost |
| Socioeconomic status (SES_U) | Unmeasured confounder | Not available | Affects plan type, region and ability to pay; partly captured through plan type and region |
| Patient/prescriber preference (Preference_U) | Unmeasured cause of drug choice | Not available | Affects drug choice; if it also affects persistence it is a confounder (addressed with E-values and a negative control outcome) |

## 5. Adjustment sets derived with dagitty

Treating SES and preference as unmeasured, dagitty returned the same minimal sufficient adjustment set for both DAGs:

**{ Age, Sex, Region, Plan type, Calendar time, Obesity severity, Comorbidity, Prior anti-obesity medication, Baseline utilization, Endocrinologist care }**

Each domain is put into practice through the covariates listed in SAP Section 7 and used in the propensity score model. Variables that are descendants of the drug (GI adverse events, weight loss, out-of-pocket cost of the index drug, and persistence for the cost outcome) were deliberately left out, because adjusting for them would remove part of the effect we want to estimate (overadjustment).

## 6. Assumptions and threats shown by the DAGs

- **Unmeasured confounding:** if patient or prescriber preference also affects persistence (for example, a patient who asks for "the newer drug" may be more motivated), the estimates are biased. This is checked with E-values (how strong such a confounder would need to be) and a negative control outcome (cancer screening), which shares healthcare-seeking confounders but should not be affected by the drug.
- **Selection (collider) bias from the enrollment requirement:** requiring 12 months of enrollment after index conditions on a post-index event. If leaving the plan is affected by both the drug (unlikely) and outcomes, this could bias results. It is a standard requirement for cost outcomes in claims and is noted as a limitation.
- **Measurement error in confounders:** BMI and comorbidities are recorded only when coded on claims, so obesity severity is partly unknown ("Unknown" category plus a sensitivity analysis restricted to patients with a recorded class).
- **Outcome misclassification:** cash-pay purchases (e.g., manufacturer self-pay vials) and copay-card use outside the plan do not appear in claims. A patient who moves to cash pay looks like a discontinuer. If this happens more with one drug (for example, Zepbound single-dose vials sold directly by the manufacturer), persistence would be underestimated for that drug.
