<!-- out: 07_reports/07_Reporting_Checklist_RECORD-PE.docx -->
# Reporting Checklist (RECORD-PE, with TARGET items)

**Tirzepatide vs semaglutide 2.4 mg: persistence, utilization and costs (synthetic claims)**

Where each item is reported in the research paper (`07_reports/06_Research_Paper.docx`). RECORD-PE extends STROBE for pharmacoepidemiology studies using routinely collected data (Langan et al., BMJ 2018); TARGET items cover the target trial emulation.

| Item | Recommendation (abbreviated) | Where reported |
|---|---|---|
| 1 Title and abstract | Design in title or abstract; informative summary | Title; Abstract |
| RECORD 1.1-1.3 | Name the data type and database; geographic region and time frame; linkage | Abstract; Methods "Data source" |
| 2 Background | Scientific background and rationale | Introduction ¶1-2 |
| 3 Objectives | Objectives and hypotheses | Introduction last ¶ |
| 4 Study design | Key elements of design early in the paper | Methods "Design" and Table: target trial specification |
| 5 Setting | Setting, locations, dates of recruitment, exposure, follow-up | Methods "Data source", "Study population" |
| 6 Participants | Eligibility criteria, sources and methods of selection | Methods "Study population"; Figure 1 |
| RECORD-PE 6.1-6.3 | Codes and algorithms for selection; validation; flow diagram | Methods; Supplementary code lists (SAP Sections 4, 6, 7); Figure 1 |
| 7 Variables | Define exposures, outcomes, confounders, effect modifiers | Methods "Exposure", "Outcomes", "Covariates" |
| RECORD-PE 7.1 | Complete list of codes and algorithms | SAP Sections 4-7; `05_code/05_build_cohort.R`, `06_baseline_covariates.R`, `07_outcomes.R` |
| RECORD-PE 7.1.a | Describe exposure definition, including days supply, grace periods and switching | Methods "Outcomes" (60-day gap, carry-over, switching) |
| 8 Data sources / measurement | Sources and methods of assessment | Methods "Data source"; Data description document |
| 9 Bias | Efforts to address bias | Methods "Statistical analysis" (new-user active-comparator design, IPTW, negative control, E-values); Discussion "Limitations" |
| 10 Study size | How the size was arrived at | Methods "Sample size" |
| 11 Quantitative variables | Handling and groupings | Methods "Covariates" |
| 12 Statistical methods | All methods, subgroups, missing data, sensitivity analyses | Methods "Statistical analysis", "Missing data", "Subgroup and sensitivity analyses" |
| RECORD 12.1-12.2 | Data cleaning methods; linkage | Methods "Data management"; Data description document Section 4 |
| 13 Participants | Numbers at each stage; flow diagram | Results ¶1; Figure 1 |
| 14 Descriptive data | Characteristics of participants; missing data | Results "Baseline characteristics"; Table 1 |
| 15 Outcome data | Numbers of outcome events | Results; Tables 2-3 |
| 16 Main results | Unadjusted and adjusted estimates with precision | Results; Tables 2-3 (crude values in step summary) |
| 17 Other analyses | Subgroups, interactions, sensitivity | Results "Subgroup and sensitivity analyses"; Table 4; Figures 6-7 |
| 18 Key results | Summary with reference to objectives | Discussion ¶1 |
| 19 Limitations | Sources of bias and imprecision | Discussion "Limitations" |
| RECORD 19.1 | Implications of using data not created for research (misclassification, unmeasured confounding, missing data, changing eligibility) | Discussion "Limitations" |
| 20 Interpretation | Cautious overall interpretation | Discussion |
| 21 Generalisability | External validity | Discussion |
| 22 Funding | Funding and role of funders | Declarations |
| RECORD 22.1 | Access to protocol, raw data and code | Declarations "Data and code availability" (GitHub repository) |
| TARGET: protocol of the target trial | Eligibility, strategies, assignment, outcomes, follow-up, causal contrast, analysis | Methods, target trial table |
| TARGET: emulation of time zero | How eligibility, assignment and start of follow-up were aligned | Methods "Design" |
| TARGET: estimand | Causal contrast and population (ATE, intention-to-treat analogue) | Methods "Statistical analysis" |
| TARGET: deviations from the target trial | Non-randomization, open treatment strategies, outcome measurement | Discussion "Limitations" |
