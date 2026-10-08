# HEOR Sample Project: Tirzepatide vs Semaglutide 2.4 mg

**Question:** Among commercially insured adults (18-64) with obesity and no type 2 diabetes who start tirzepatide (Zepbound) or semaglutide 2.4 mg (Wegovy), does tirzepatide lead to higher 12-month persistence and different healthcare utilization and costs?

See `01_protocol/Research_Question_and_Aims.docx` for the topic, background, aims and design.

> **The data are fully synthetic.** No real patients. Results are a methods exercise, not evidence about either drug.

## Folder structure

| Folder | Contents |
|---|---|
| `01_protocol/` | Research question and aims. Put your SAP, DAG and protocol drafts here. |
| `02_data_raw/` | The raw claims extract, exactly as "delivered by the vendor". **Never edit these files.** |
| `03_reference/` | Data dictionary and code lookup tables (NDC, ICD-10-CM, CPT/HCPCS, place of service, revenue codes, provider specialty, state-to-region). |
| `04_data_derived/` | Everything your code creates (cleaned tables, cohort, analytic dataset). Safe to delete and rebuild. |
| `05_code/` | R scripts, run in numbered order. |
| `06_output/` | Tables and figures. |

## The raw extract

| File | Grain | Notes |
|---|---|---|
| `members.csv` | one row per member (supposedly) | birth year, sex, state |
| `enrollment.csv` | one row per eligibility segment | medical and pharmacy coverage flags, plan type, employer group |
| `pharmacy_claims_YYYY.csv.gz` | one row per pharmacy claim transaction | all drugs, not just the study drugs; includes reversals |
| `medical_claims_YYYY.csv.gz` | one row per claim line | professional and facility claims; up to 5 ICD-10-CM codes per claim |

- Extract period: 2023-01-01 to 2026-06-30. Members were selected because they had at least one fill of an anti-obesity medication or GLP-1 receptor agonist; most will not meet the study criteria.
- Claim files are split by calendar year and gzip-compressed. R reads `.csv.gz` directly, so there is no need to unzip them.
- Read all code fields (NDC, ICD-10, CPT, place of service, revenue code) as **character**.
- Costs are allowed amounts in nominal U.S. dollars. Manufacturer rebates and cash-pay purchases (e.g., LillyDirect, NovoCare) never appear in claims.
- Like any real extract, these files contain data-quality problems. Finding and documenting them is part of the exercise (`05_code/02_data_quality_review.R`).
- NDCs follow real formats; the study-drug NDCs are modeled on the manufacturers' published codes, and others are illustrative. Use the lookup in `03_reference/`. In a real study, verify codes against the FDA NDC Directory.

## Getting started in R

1. Double-click `HEOR_Tirzepatide_Project.Rproj` to open the project in RStudio.
2. Run `05_code/00_setup.R` (installs and loads packages; first run takes a few minutes).
3. Run `05_code/01_import_raw.R` to read and stack the raw files into `04_data_derived/`.
4. Scripts `02` to `10` are empty templates in workflow order. Write the SAP before filling them in.

## Workflow position

Steps 1-4 of the project workflow (question, literature, design, data source) are done. Next: **Step 5, the statistical analysis plan**, before any data cleaning or analysis.
