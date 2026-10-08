# HEOR Sample Project: Tirzepatide vs Semaglutide 2.4 mg

**Question:** Among commercially insured adults (18-64) with obesity and no type 2 diabetes who start tirzepatide (Zepbound) or semaglutide 2.4 mg (Wegovy), does tirzepatide lead to higher 12-month persistence and different healthcare utilization and costs?

See `01_protocol/Research_Question_and_Aims.docx` for the topic, background, aims and design, and `Research_Question_Workflow.docx` for the 12-step workflow this project follows.

> **The data are fully synthetic.** No real patients. Results are a methods exercise, not evidence about either drug.

## Deliverables

| # | Deliverable | File |
|---|---|---|
| 1 | Annotated R Markdown (run in RStudio: open the .Rproj, then Knit) | `HEOR_Tirzepatide_Analysis.Rmd` |
| 2 | Data description (claims features; why claims data) | `01_protocol/01_Data_Description.docx` |
| 3 | Literature review and synthesis tables | `01_protocol/02_Literature_Review_and_Synthesis.docx` |
| 4 | Study protocol and statistical analysis plan (SAP) | `01_protocol/03_Study_Protocol_and_Statistical_Analysis_Plan.docx` |
| 5 | Directed acyclic graphs | `01_protocol/04_Directed_Acyclic_Graphs.docx` |
| 6 | Research step summary (decisions from start to finish) | `07_reports/05_Research_Step_Summary.docx` |
| 7 | Research paper | `07_reports/06_Research_Paper.docx` |
| 8 | RECORD-PE / TARGET reporting checklist | `07_reports/07_Reporting_Checklist_RECORD-PE.docx` |
| 9 | Data quality log, cohort attrition, result tables | `06_output/tables/` |
| 10 | Figures (DAGs, flow diagram, balance, Kaplan-Meier, costs, forest plots) | `06_output/figures/` |

The Markdown sources of the Word documents are in `docs_src/`; rebuild them with `Rscript 05_code/99_build_docs.R`.

## Folder structure

| Folder | Contents |
|---|---|
| `01_protocol/` | Research question and aims, data description, literature review, SAP, DAGs. Full-text literature is kept locally only (copyright). |
| `02_data_raw/` | The raw claims extract, exactly as "delivered by the vendor". **Never edit these files.** |
| `03_reference/` | Data dictionary and code lookup tables (NDC, ICD-10-CM, CPT/HCPCS, place of service, revenue codes, provider specialty, state-to-region). |
| `04_data_derived/` | Everything the code creates (cleaned tables, cohort, analytic dataset). Not on GitHub; rebuilt by the code. |
| `05_code/` | R scripts, run in numbered order (00 to 10), plus builders for the R Markdown (98) and Word documents (99). |
| `06_output/` | Tables (CSV) and figures (PNG). |
| `07_reports/` | Research step summary, research paper, reporting checklist. |
| `docs_src/` | Markdown sources for the Word deliverables. |

## Reproducing the analysis

Reference environment: R 4.4.1 (x86_64-apple-darwin20), macOS 15.7.9, locale en_US.UTF-8, time zone America/New_York.

**Option A, RStudio:** double-click `HEOR_Tirzepatide_Project.Rproj`, open `HEOR_Tirzepatide_Analysis.Rmd` and click Knit (or run chunks top to bottom).

**Option B, terminal (from the project folder):**

```bash
for s in 01_import_raw 00b_dag 02_data_quality_review 03_clean_enrollment 04_clean_claims 05_build_cohort 06_baseline_covariates 07_outcomes 08_table1_and_weighting 09_models 10_subgroup_sensitivity; do Rscript 05_code/$s.R || break; done
```

`00_setup.R` is sourced by every script and installs missing packages.

## Workflow position

All 12 workflow steps are complete. The SAP (step 5) was committed to this repository before any outcome was derived (commit "SAP v1.0 ..."); see the research step summary for every decision and any deviation.
