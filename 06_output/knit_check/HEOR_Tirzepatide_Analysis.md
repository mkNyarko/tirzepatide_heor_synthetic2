---
title: "Tirzepatide vs Semaglutide 2.4 mg: Persistence, Utilization and Costs"
subtitle: "Annotated analysis of a synthetic commercial claims extract (target trial emulation)"
author: "Maxwell K. Nyarko"
date: "October 2026"
output:
  html_document:
    toc: true
    toc_float: true
    number_sections: false
    df_print: paged
---



# How to use this file

1. Open `HEOR_Tirzepatide_Project.Rproj` in RStudio (this sets the working folder).
2. Open this file and either click **Knit** (runs everything and makes an HTML report) or run the chunks one at a time from top to bottom with the green arrow on each chunk (Ctrl/Cmd + Shift + Enter).
3. The first chunk installs any missing packages, which can take a few minutes the first time. A full run takes about 5-10 minutes; the bootstrap in Step 9.6 is the slowest part.

Every step below has the same layout: **Step**, **What** (each key action and the code line that does it), **Why**, then the R code. Each step saves its results to `04_data_derived/` or `06_output/`, so you can stop and restart at any step after the setup chunk.

**The data are fully synthetic.** Results show how the methods work and are not evidence about either drug.

The same code is also saved as numbered scripts in `05_code/` (00 to 10); this file is assembled from those scripts by `05_code/98_build_rmd.R`.

# Step 0. Set up R

**What**

- Install and load the packages for data handling, weighting, models and figures: `install.packages(to_install)` and `lapply(pkgs, library, ...)`.
- Make `select()` refer to dplyr (MASS also has a `select()`): `select <- dplyr::select`.

**Why.** Every later step uses these packages. Loading them once at the start makes the run reproducible and avoids errors halfway through.


``` r
pkgs <- c(
  # data handling
  "here", "data.table", "dplyr", "tidyr", "stringr", "lubridate", "readr", "janitor",
  # descriptive tables
  "gtsummary", "tableone", "flextable", "officer",
  # confounding adjustment and balance
  "WeightIt", "MatchIt", "cobalt",
  # models
  "survival", "survminer", "sandwich", "lmtest", "broom", "MASS", "pscl", "marginaleffects",
  # sensitivity analysis
  "EValue",
  # DAG
  "dagitty", "ggdag",
  # figures
  "ggplot2", "patchwork", "scales"
)
to_install <- setdiff(pkgs, rownames(installed.packages()))
if (length(to_install) > 0) install.packages(to_install, repos = "https://cloud.r-project.org")
suppressPackageStartupMessages(invisible(lapply(pkgs, library, character.only = TRUE)))
# MASS masks dplyr::select; make sure select() means dplyr::select()
select <- dplyr::select
```

**What**

- Define folder paths with `here::here()` so the code works on any computer.
- Store the study calendar from the protocol: identification window (`index_start`, `index_end`), 365-day baseline and follow-up, the 60-day persistence gap (`gap_days`), and the 30-day allowed enrollment gap.
- Fix the random seed with `set.seed(20261007)` so the bootstrap gives the same answer each time.

**Why.** Keeping all design constants in one place means a design change is made once, and readers can check the code against the SAP.


``` r
dir_raw     <- here::here("02_data_raw")
dir_ref     <- here::here("03_reference")
dir_derived <- here::here("04_data_derived")
dir_tables  <- here::here("06_output", "tables")
dir_figures <- here::here("06_output", "figures")
for (d in c(dir_derived, dir_tables, dir_figures)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

# ---- study calendar (from the protocol) --------------------------------------
data_start    <- as.Date("2023-01-01")
data_end      <- as.Date("2026-06-30")
index_start   <- as.Date("2024-01-01")
index_end     <- as.Date("2025-06-30")
baseline_days <- 365   # baseline = index - 365 to index - 1
followup_days <- 365   # follow-up = index to index + 364
gap_days      <- 60    # primary persistence grace period (SAP section 6.1)
enroll_gap_allowed <- 30  # enrollment gaps of <= 30 days are bridged (SAP section 4)

set.seed(20261007)
theme_set(theme_minimal(base_size = 11))
col_drug <- c("Tirzepatide" = "#1F6FB4", "Semaglutide 2.4 mg" = "#D9822B")
message("Setup complete. Raw data in: ", dir_raw)
```

# Step 1. Study design: the DAG (workflow step 3)

**What**

- Write the assumed causal structure as a DAG with `dagitty::dagitty()`: one for persistence (`dag_persist`) and one for costs (`dag_cost`).
- Mark the exposure (`Drug`) and outcome, and list unmeasured nodes (`SES_U`, `Preference_U`).

**Why.** The DAG makes our assumptions explicit and tells us which variables to adjust for (confounders) and which to leave alone (mediators such as GI side effects or the drug's copay).


``` r
# Nodes measured in claims are written in CamelCase; unmeasured nodes end in "_U".
dag_persist <- dagitty::dagitty('dag {
  Drug [exposure]
  Persistence [outcome]
  Age -> {Drug Persistence ObesitySeverity Comorbidity BaselineUse}
  Sex -> {Drug Persistence Comorbidity}
  Region -> {Drug Persistence PlanType}
  PlanType -> {Drug Persistence OOPCost}
  CalendarTime -> {Drug Persistence}
  ObesitySeverity -> {Drug Persistence Comorbidity}
  Comorbidity -> {Drug Persistence BaselineUse}
  PriorAOM -> {Drug Persistence}
  BaselineUse -> {Drug Persistence}
  Endocrinologist -> {Drug Persistence}
  SES_U -> {PlanType Region Persistence}
  Preference_U -> {Drug}
  Drug -> {GI_AE WeightLoss OOPCost Persistence}
  GI_AE -> Persistence
  WeightLoss -> Persistence
  OOPCost -> Persistence
  Comorbidity -> Endocrinologist
  ObesitySeverity -> PriorAOM
}')

# Cost outcome DAG: persistence becomes a mediator between drug and costs
dag_cost <- dagitty::dagitty('dag {
  Drug [exposure]
  Costs [outcome]
  Age -> {Drug Costs ObesitySeverity Comorbidity BaselineUse}
  Sex -> {Drug Costs Comorbidity}
  Region -> {Drug Costs PlanType}
  PlanType -> {Drug Costs}
  CalendarTime -> {Drug Costs}
  ObesitySeverity -> {Drug Costs Comorbidity}
  Comorbidity -> {Drug Costs BaselineUse}
  PriorAOM -> {Drug Costs}
  BaselineUse -> {Drug Costs}
  Endocrinologist -> {Drug Costs}
  SES_U -> {PlanType Region Costs}
  Preference_U -> {Drug}
  Drug -> {Persistence GI_AE Costs}
  Persistence -> Costs
  GI_AE -> {Persistence Costs}
  Comorbidity -> Endocrinologist
  ObesitySeverity -> PriorAOM
}')
```

**What**

- Ask dagitty for the minimal sufficient adjustment set: `adjustmentSets(dag_persist, type = "minimal")`.
- List the descendants of `Drug`, which must not be adjusted for: `descendants(dag_persist, "Drug")`.

**Why.** This turns the DAG into a concrete covariate list for the propensity score model (Step 8).


``` r
# Minimal sufficient adjustment sets (unmeasured nodes cannot be used)
latent <- c("SES_U", "Preference_U")
dagitty::latents(dag_persist) <- latent
dagitty::latents(dag_cost)    <- latent
adj_persist <- dagitty::adjustmentSets(dag_persist, type = "minimal")
adj_cost    <- dagitty::adjustmentSets(dag_cost, type = "minimal")
print(adj_persist); print(adj_cost)
```

```
## { Age, BaselineUse, CalendarTime, Comorbidity, Endocrinologist,
##   ObesitySeverity, PlanType, PriorAOM, Region, Sex }
```

```
## { Age, BaselineUse, CalendarTime, Comorbidity, Endocrinologist,
##   ObesitySeverity, PlanType, PriorAOM, Region, Sex }
```

``` r
cat("Mediators NOT to adjust for (descendants of Drug):",
    paste(setdiff(dagitty::descendants(dag_persist, "Drug"), c("Drug", "Persistence")), collapse = ", "), "\n")
```

```
## Mediators NOT to adjust for (descendants of Drug): WeightLoss, OOPCost, GI_AE
```

``` r
writeLines(c("Persistence DAG - minimal adjustment set(s):", capture.output(print(adj_persist)),
             "", "Cost DAG - minimal adjustment set(s):", capture.output(print(adj_cost))),
           file.path(dir_tables, "dag_adjustment_sets.txt"))
```

**What.** Plot both DAGs with nodes coloured by role (`plot_dag()`) and save them to `06_output/figures/`.

**Why.** A picture of the assumptions goes into the DAG document and the paper.


``` r
node_role <- function(dag, outcome) {
  tidy <- ggdag::tidy_dagitty(dag, layout = "sugiyama", seed = 3)
  tidy$data <- tidy$data |>
    mutate(role = case_when(
      name == "Drug" ~ "Exposure",
      name == outcome ~ "Outcome",
      grepl("_U$", name) ~ "Unmeasured",
      name %in% c("GI_AE", "WeightLoss", "OOPCost", "Persistence") ~ "Mediator (do not adjust)",
      TRUE ~ "Measured confounder (adjusted)"))
  tidy
}
plot_dag <- function(dag, outcome, title) {
  ggplot(node_role(dag, outcome), aes(x = x, y = y, xend = xend, yend = yend)) +
    ggdag::geom_dag_edges(edge_colour = "grey55", edge_width = 0.35) +
    ggdag::geom_dag_point(aes(colour = role), size = 19) +
    ggdag::geom_dag_text(colour = "black", size = 2.6) +
    scale_colour_manual(values = c("Exposure" = "#7FB3E0", "Outcome" = "#F2B880",
                                   "Unmeasured" = "#D9D9D9", "Mediator (do not adjust)" = "#E6A0A0",
                                   "Measured confounder (adjusted)" = "#A8D5A2"), name = NULL) +
    ggdag::theme_dag() + theme(legend.position = "bottom") +
    guides(colour = guide_legend(nrow = 2)) +
    labs(title = title)
}
p_dag1 <- plot_dag(dag_persist, "Persistence", "DAG 1. Tirzepatide vs semaglutide 2.4 mg and 12-month persistence")
p_dag2 <- plot_dag(dag_cost, "Costs", "DAG 2. Tirzepatide vs semaglutide 2.4 mg and 12-month costs / utilization")
ggsave(file.path(dir_figures, "fig0_dag_persistence.png"), p_dag1, width = 11, height = 7.5, dpi = 200, bg = "white")
ggsave(file.path(dir_figures, "fig0_dag_costs.png"), p_dag2, width = 11, height = 7.5, dpi = 200, bg = "white")
```

# Step 2. Import the raw extract (workflow step 7 begins)

**What**

- Declare column types so all codes are read as text (`rx_types`, `med_types`; e.g. `ndc = col_character()`).
- Read and stack the yearly gzip files with `read_stack()`.
- Read the members, enrollment and reference tables with `readr::read_csv()`.

**Why.** Reading NDC, ICD-10, CPT and place-of-service codes as numbers would drop leading zeros and silently break code matching. Nothing is cleaned here, so the raw data stay exactly as delivered.


``` r
# Codes must be read as character so leading zeros are not lost on import.
rx_types <- cols(
  rx_claim_id = col_character(), member_id = col_character(), fill_date = col_date(),
  ndc = col_character(), days_supply = col_integer(), quantity = col_double(),
  refill_number = col_integer(), claim_status = col_character(),
  pharmacy_channel = col_character(), allowed_amt = col_double(),
  paid_amt = col_double(), member_oop = col_double()
)
med_types <- cols(
  claim_id = col_character(), line_num = col_integer(), member_id = col_character(),
  claim_type = col_character(), service_from_date = col_date(), service_to_date = col_date(),
  admit_date = col_date(), discharge_date = col_date(), place_of_service = col_character(),
  revenue_code = col_character(), proc_code = col_character(),
  dx1 = col_character(), dx2 = col_character(), dx3 = col_character(),
  dx4 = col_character(), dx5 = col_character(), prov_specialty = col_character(),
  allowed_amt = col_double(), paid_amt = col_double()
)

read_stack <- function(pattern, types) {
  files <- list.files(dir_raw, pattern = pattern, full.names = TRUE)
  message("Reading: ", paste(basename(files), collapse = ", "))
  dplyr::bind_rows(lapply(files, readr::read_csv, col_types = types, progress = FALSE))
}

members    <- readr::read_csv(file.path(dir_raw, "members.csv"),
                              col_types = cols(.default = col_character(), birth_year = col_integer()))
enrollment <- readr::read_csv(file.path(dir_raw, "enrollment.csv"),
                              col_types = cols(.default = col_character(),
                                               eligibility_start = col_date(), eligibility_end = col_date()))
pharmacy   <- read_stack("^pharmacy_claims_\\d{4}\\.csv\\.gz$", rx_types)
medical    <- read_stack("^medical_claims_\\d{4}\\.csv\\.gz$", med_types)

# reference tables
ndc_lookup <- readr::read_csv(file.path(dir_ref, "ndc_product_lookup.csv"), col_types = cols(.default = col_character()))
icd_lookup <- readr::read_csv(file.path(dir_ref, "icd10cm_codes.csv"), col_types = cols(.default = col_character()))
```

**What.** Print row and column counts and parsing problems for each table, then save R copies with `saveRDS()`.

**Why.** A structural check right after import catches truncated files or type problems before they cause trouble later.


``` r
# quick structural check (row counts, parsing problems)
for (nm in c("members", "enrollment", "pharmacy", "medical")) {
  x <- get(nm)
  message(sprintf("%-11s rows: %s  cols: %s  parse problems: %s",
                  nm, format(nrow(x), big.mark = ","), ncol(x), nrow(readr::problems(x))))
}

saveRDS(members,    file.path(dir_derived, "raw_members.rds"))
saveRDS(enrollment, file.path(dir_derived, "raw_enrollment.rds"))
saveRDS(pharmacy,   file.path(dir_derived, "raw_pharmacy.rds"))
saveRDS(medical,    file.path(dir_derived, "raw_medical.rds"))
message("Raw tables saved to 04_data_derived/")
```

# Step 3. Data quality review

**What**

- Reload the raw tables (`readRDS()`).
- Create a log with one row per check, using `log_check(table, check, n_affected, decision)`.

**Why.** Vendor claims always contain errors. Finding them before cleaning, and writing down a decision for each, makes the cleaning transparent and reproducible (workflow step 7: "log every data-cleaning decision").


``` r
members    <- readRDS(file.path(dir_derived, "raw_members.rds"))
enrollment <- readRDS(file.path(dir_derived, "raw_enrollment.rds"))
pharmacy   <- readRDS(file.path(dir_derived, "raw_pharmacy.rds"))
medical    <- readRDS(file.path(dir_derived, "raw_medical.rds"))
ndc_lookup <- readr::read_csv(file.path(dir_ref, "ndc_product_lookup.csv"),
                              col_types = cols(.default = col_character()))

# Each check adds one row: table, check, number of rows affected, decision taken
dq <- list()
log_check <- function(table, check, n, decision) {
  dq[[length(dq) + 1]] <<- tibble(table = table, check = check, n_affected = n, decision = decision)
}
```

**What.** Members: count exact duplicates (`duplicated()`), IDs with conflicting demographics (`count(member_id) |> filter(n > 1)`), missing birth year or state, and unknown sex.

**Why.** A member ID should identify one person. Conflicting records mean we cannot know the person's sex or age.


``` r
dup_ids     <- members$member_id[duplicated(members$member_id)]
exact_dups  <- sum(duplicated(data.table::as.data.table(members)))
conflicting <- members |> distinct() |> count(member_id) |> filter(n > 1) |> nrow()
log_check("members", "Exact duplicate rows", exact_dups, "Drop exact duplicates")
log_check("members", "Member IDs with conflicting demographics (e.g., different sex)", conflicting,
          "Cannot tell which record is right: exclude these members from the cohort")
log_check("members", "Missing birth year", sum(is.na(members$birth_year)),
          "Age cannot be computed: excluded at the age criterion")
log_check("members", "Sex unknown (U)", sum(members$sex == "U", na.rm = TRUE),
          "Excluded (complete-case on sex; < 1% of members)")
log_check("members", "Missing state", sum(is.na(members$state)), "Region set to 'Unknown' category")
log_check("members", "Birth year implies age < 18 in 2024", sum(members$birth_year > 2006, na.rm = TRUE),
          "Removed by the age 18-64 criterion")
```

**What.** Enrollment: count duplicate segments, overlapping segments (`eligibility_start <= prev_end`), gaps (`eligibility_start > prev_end + 1`), and segments without drug or medical coverage.

**Why.** Continuous enrollment is an eligibility criterion, and pharmacy claims exist only while drug coverage is active.


``` r
enr_sorted <- enrollment |> distinct() |> arrange(member_id, eligibility_start) |>
  group_by(member_id) |> mutate(prev_end = lag(eligibility_end)) |> ungroup()
log_check("enrollment", "Exact duplicate segments", sum(duplicated(data.table::as.data.table(enrollment))), "Drop exact duplicates")
log_check("enrollment", "Overlapping segments for the same member",
          sum(enr_sorted$eligibility_start <= enr_sorted$prev_end, na.rm = TRUE),
          "Collapse overlapping segments into one continuous span")
log_check("enrollment", "Gaps between segments (> 1 day)",
          sum(enr_sorted$eligibility_start > enr_sorted$prev_end + 1, na.rm = TRUE),
          "Gaps <= 30 days bridged; longer gaps break continuous enrollment")
log_check("enrollment", "Segments without pharmacy coverage (rx_coverage = N)",
          sum(enrollment$rx_coverage != "Y"), "Not counted as covered time (pharmacy claims not captured)")
log_check("enrollment", "Segments without medical coverage", sum(enrollment$medical_coverage != "Y"),
          "Not counted as covered time")
```

**What.** Pharmacy: count the three NDC formats (`nchar(pharmacy$ndc)`), duplicates, reversals (`claim_status == "R"`), missing allowed amounts, and implausible days supply (< 3 or > 90).

**Why.** NDCs must match the lookup to identify the study drugs; reversals are claims that were never dispensed; days supply drives persistence and PDC.


``` r
log_check("pharmacy", "NDC hyphenated 5-4-2 format (13 characters)", sum(nchar(pharmacy$ndc) == 13),
          "Remove hyphens")
log_check("pharmacy", "NDC hyphenated 4-4-2 format (12 characters, labeler lost a leading zero)",
          sum(nchar(pharmacy$ndc) == 12), "Remove hyphens and pad labeler to 5 digits")
log_check("pharmacy", "NDC stored as number (leading zeros lost; < 11 digits)",
          sum(!grepl("-", pharmacy$ndc) & nchar(pharmacy$ndc) < 11), "Left-pad with zeros to 11 digits")
log_check("pharmacy", "Exact duplicate rows", sum(duplicated(data.table::as.data.table(pharmacy))), "Drop exact duplicates")
log_check("pharmacy", "Reversed claims (claim_status = R)", sum(pharmacy$claim_status == "R"),
          "Drop the reversal and the paid claim it reverses (same rx_claim_id)")
paid <- pharmacy |> filter(claim_status == "P")
log_check("pharmacy", "Same paid rx_claim_id appearing more than once (format-only differences)",
          sum(duplicated(paid$rx_claim_id)) - sum(duplicated(data.table::as.data.table(paid))), "Keep one row per rx_claim_id")
log_check("pharmacy", "Missing allowed amount", sum(is.na(pharmacy$allowed_amt)),
          "Impute as paid_amt + member_oop (identity holds in all complete rows)")
log_check("pharmacy", "Implausible days supply on paid claims (< 3 or > 90 days)",
          sum(pharmacy$claim_status == "P" & (pharmacy$days_supply < 3 | pharmacy$days_supply > 90)),
          "Replace with the most common days supply for the same product and quantity")
```

**What.** Medical: count duplicates, lower-case and dotted ICD-10 codes, place of service with a lost zero, missing or negative allowed amounts, very large amounts, and obesity-class codes used before their effective date.

**Why.** Diagnosis codes define obesity, diabetes and comorbidities; cost fields define the economic outcomes.


``` r
dx_long <- unlist(medical[, paste0("dx", 1:5)], use.names = FALSE)
dx_long <- dx_long[!is.na(dx_long)]
log_check("medical", "Exact duplicate lines", sum(duplicated(data.table::as.data.table(medical))), "Drop exact duplicates")
log_check("medical", "ICD-10-CM codes in lower case", sum(dx_long != toupper(dx_long)), "Convert to upper case")
log_check("medical", "ICD-10-CM codes with a decimal point (mixed formats)", sum(grepl(".", dx_long, fixed = TRUE)),
          "Remove the decimal point (match on undotted codes)")
log_check("medical", "Place of service with leading zero lost ('2' instead of '02')",
          sum(nchar(medical$place_of_service) == 1, na.rm = TRUE), "Left-pad to 2 characters")
log_check("medical", "Duplicate claim_id + line_num after code normalization",
          sum(duplicated(data.table::as.data.table(medical[, c("claim_id", "line_num")]))) - sum(duplicated(data.table::as.data.table(medical))),
          "Keep one row per claim line")
log_check("medical", "Missing allowed amount", sum(is.na(medical$allowed_amt)),
          "Impute as paid_amt / median(paid/allowed ratio) for the same claim type")
log_check("medical", "Negative allowed amounts (adjustment lines, line_num >= 51)", sum(medical$allowed_amt < 0, na.rm = TRUE),
          "Keep: adjustments net against the claim; claim totals floored at $0")
log_check("medical", "Very large line amounts (> $100,000; inpatient stays)", sum(medical$allowed_amt > 1e5, na.rm = TRUE),
          "Keep (plausible); costs winsorized at the 99th percentile in a sensitivity analysis")
log_check("medical", "Obesity class codes E66.811-E66.813 used before their 2024-10-01 effective date",
          sum(grepl("^E66\\.?81[123]", toupper(medical$dx1)) & medical$service_from_date < as.Date("2024-10-01")),
          "None found; codes accepted from 2024-10-01")
```

**What.** Combine the checks with `bind_rows(dq)` and save `06_output/tables/data_quality_log.csv`.

**Why.** The log is a deliverable and is summarized in the data description document.


``` r
dq_log <- bind_rows(dq)
readr::write_csv(dq_log, file.path(dir_tables, "data_quality_log.csv"))
print(dq_log, n = Inf, width = 200)
```

```
## # A tibble: 28 × 4
##    table     
##    <chr>     
##  1 members   
##  2 members   
##  3 members   
##  4 members   
##  5 members   
##  6 members   
##  7 enrollment
##  8 enrollment
##  9 enrollment
## 10 enrollment
## 11 enrollment
## 12 pharmacy  
## 13 pharmacy  
## 14 pharmacy  
## 15 pharmacy  
## 16 pharmacy  
## 17 pharmacy  
## 18 pharmacy  
## 19 pharmacy  
## 20 medical   
## 21 medical   
## 22 medical   
## 23 medical   
## 24 medical   
## 25 medical   
## 26 medical   
## 27 medical   
## 28 medical   
##    check                                                                        
##    <chr>                                                                        
##  1 Exact duplicate rows                                                         
##  2 Member IDs with conflicting demographics (e.g., different sex)               
##  3 Missing birth year                                                           
##  4 Sex unknown (U)                                                              
##  5 Missing state                                                                
##  6 Birth year implies age < 18 in 2024                                          
##  7 Exact duplicate segments                                                     
##  8 Overlapping segments for the same member                                     
##  9 Gaps between segments (> 1 day)                                              
## 10 Segments without pharmacy coverage (rx_coverage = N)                         
## 11 Segments without medical coverage                                            
## 12 NDC hyphenated 5-4-2 format (13 characters)                                  
## 13 NDC hyphenated 4-4-2 format (12 characters, labeler lost a leading zero)     
## 14 NDC stored as number (leading zeros lost; < 11 digits)                       
## 15 Exact duplicate rows                                                         
## 16 Reversed claims (claim_status = R)                                           
## 17 Same paid rx_claim_id appearing more than once (format-only differences)     
## 18 Missing allowed amount                                                       
## 19 Implausible days supply on paid claims (< 3 or > 90 days)                    
## 20 Exact duplicate lines                                                        
## 21 ICD-10-CM codes in lower case                                                
## 22 ICD-10-CM codes with a decimal point (mixed formats)                         
## 23 Place of service with leading zero lost ('2' instead of '02')                
## 24 Duplicate claim_id + line_num after code normalization                       
## 25 Missing allowed amount                                                       
## 26 Negative allowed amounts (adjustment lines, line_num >= 51)                  
## 27 Very large line amounts (> $100,000; inpatient stays)                        
## 28 Obesity class codes E66.811-E66.813 used before their 2024-10-01 effective d…
##    n_affected decision                                                          
##         <int> <chr>                                                             
##  1         44 Drop exact duplicates                                             
##  2         22 Cannot tell which record is right: exclude these members from the…
##  3         23 Age cannot be computed: excluded at the age criterion             
##  4         62 Excluded (complete-case on sex; < 1% of members)                  
##  5         49 Region set to 'Unknown' category                                  
##  6        177 Removed by the age 18-64 criterion                                
##  7        470 Drop exact duplicates                                             
##  8       1986 Collapse overlapping segments into one continuous span            
##  9       1114 Gaps <= 30 days bridged; longer gaps break continuous enrollment  
## 10        252 Not counted as covered time (pharmacy claims not captured)        
## 11          0 Not counted as covered time                                       
## 12     127841 Remove hyphens                                                    
## 13      21683 Remove hyphens and pad labeler to 5 digits                        
## 14       9379 Left-pad with zeros to 11 digits                                  
## 15       2964 Drop exact duplicates                                             
## 16      10535 Drop the reversal and the paid claim it reverses (same rx_claim_i…
## 17       2310 Keep one row per rx_claim_id                                      
## 18       1582 Impute as paid_amt + member_oop (identity holds in all complete r…
## 19        961 Replace with the most common days supply for the same product and…
## 20       2706 Drop exact duplicates                                             
## 21      49863 Convert to upper case                                             
## 22     216122 Remove the decimal point (match on undotted codes)                
## 23        649 Left-pad to 2 characters                                          
## 24       2402 Keep one row per claim line                                       
## 25       1916 Impute as paid_amt / median(paid/allowed ratio) for the same clai…
## 26       3193 Keep: adjustments net against the claim; claim totals floored at …
## 27        147 Keep (plausible); costs winsorized at the 99th percentile in a se…
## 28          0 None found; codes accepted from 2024-10-01
```

# Step 4. Clean members and enrollment

**What**

- Drop exact duplicate member rows (`distinct()`) and flag IDs that still have more than one row (`demo_conflict = n() > 1`).
- Add census region from the state lookup (`left_join(... state_census_region.csv)`), with "Unknown" when state is missing.

**Why.** One clean row per member is needed before joining; flagged members are excluded at cohort step 4.


``` r
members <- readRDS(file.path(dir_derived, "raw_members.rds"))
members_clean <- members |>
  distinct() |>                                   # drop exact duplicate rows
  group_by(member_id) |>
  mutate(demo_conflict = n() > 1) |>              # same ID, different demographics
  slice(1) |>
  ungroup() |>
  left_join(readr::read_csv(file.path(dir_ref, "state_census_region.csv"), show_col_types = FALSE),
            by = "state") |>
  mutate(region = coalesce(census_region, "Unknown")) |>
  select(member_id, birth_year, sex, state, region, demo_conflict)
saveRDS(members_clean, file.path(dir_derived, "members_clean.rds"))
count(members_clean, demo_conflict)
```

```
## # A tibble: 2 × 2
##   demo_conflict     n
##   <lgl>         <int>
## 1 FALSE         14678
## 2 TRUE             22
```

**What**

- Keep segments with both medical and pharmacy coverage (`filter(medical_coverage == "Y", rx_coverage == "Y")`).
- Merge overlapping or nearly adjacent segments into continuous spans: `cummax()` tracks the latest end date, and a new span starts only when the next segment begins more than 30 days later (`new_span`).

**Why.** Continuous enrollment (365 days before and after index) guarantees we see all claims in the baseline and follow-up windows, so a missing claim means no care, not missing data.


``` r
enrollment <- readRDS(file.path(dir_derived, "raw_enrollment.rds"))

# Covered time = segments with BOTH medical and pharmacy coverage
segments <- enrollment |>
  distinct() |>
  filter(medical_coverage == "Y", rx_coverage == "Y") |>
  arrange(member_id, eligibility_start)
saveRDS(segments, file.path(dir_derived, "enrollment_segments.rds"))  # used for plan type at index

# Collapse overlapping/adjacent segments into continuous spans.
# A new span starts only when a segment begins more than `enroll_gap_allowed` days
# after the latest end date seen so far for that member.
spans <- segments |>
  group_by(member_id) |>
  mutate(run_end   = as.Date(cummax(as.numeric(eligibility_end))),
         new_span  = eligibility_start > lag(run_end) + 1 + enroll_gap_allowed,
         new_span  = coalesce(new_span, TRUE),
         span_id   = cumsum(new_span)) |>
  group_by(member_id, span_id) |>
  summarise(span_start = min(eligibility_start), span_end = max(eligibility_end), .groups = "drop")
saveRDS(spans, file.path(dir_derived, "enrollment_spans.rds"))
message("Segments: ", nrow(segments), " -> continuous spans: ", nrow(spans),
        " for ", n_distinct(spans$member_id), " members")
```

# Step 5. Clean pharmacy and medical claims

**What**

- Convert every NDC to 11 digits with `normalize_ndc()` (remove hyphens, pad the labeler, restore lost leading zeros).
- Remove reversed claims and the paid claims they reverse (`!rx_claim_id %in% reversed_ids`), and keep one row per claim (`distinct(rx_claim_id, ...)`).
- Fill missing allowed amounts as paid + out-of-pocket (`coalesce()`), and add drug names from the lookup (`left_join(ndc_lookup ...)`).
- Replace implausible days supply with the most common value for the same NDC and quantity (`ds_mode`, `days_supply_fixed`).
- Check that every NDC matched (`stopifnot()`).

**Why.** Without these fixes some Zepbound and Wegovy fills would be missed, reversed fills would count as treatment, and a "999-day" supply would make a patient look persistent for years.


``` r
pharmacy   <- readRDS(file.path(dir_derived, "raw_pharmacy.rds"))
ndc_lookup <- readr::read_csv(file.path(dir_ref, "ndc_product_lookup.csv"),
                              col_types = cols(.default = col_character()))

# NDCs arrive in three formats; convert all to the 11-digit (5-4-2) form used by the lookup
normalize_ndc <- function(x) {
  digits <- gsub("-", "", x)
  out <- ifelse(grepl("-", x) & nchar(x) == 12, paste0("0", digits), digits)  # 4-4-2 -> 5-4-2
  stringr::str_pad(out, 11, side = "left", pad = "0")                         # lost leading zeros
}

reversed_ids <- pharmacy$rx_claim_id[pharmacy$claim_status == "R"]

pharmacy_clean <- pharmacy |>
  mutate(ndc11 = normalize_ndc(ndc)) |>
  filter(claim_status == "P", !rx_claim_id %in% reversed_ids) |>  # drop reversals and what they reverse
  distinct(rx_claim_id, .keep_all = TRUE) |>                       # one row per paid claim
  mutate(allowed_amt = coalesce(allowed_amt, paid_amt + member_oop)) |>
  left_join(ndc_lookup |> select(ndc11, product_name, generic_name, strength, therapeutic_class),
            by = "ndc11")

# Implausible days supply (< 3 or > 90): use the most common value for the same NDC and quantity
mode_val <- function(x) as.integer(names(which.max(table(x))))
ds_mode <- pharmacy_clean |>
  filter(between(days_supply, 3, 90)) |>
  group_by(ndc11, quantity) |>
  summarise(ds_typical = mode_val(days_supply), .groups = "drop")
ds_mode_ndc <- pharmacy_clean |>
  filter(between(days_supply, 3, 90)) |>
  group_by(ndc11) |>
  summarise(ds_typical_ndc = mode_val(days_supply), .groups = "drop")

pharmacy_clean <- pharmacy_clean |>
  left_join(ds_mode, by = c("ndc11", "quantity")) |>
  left_join(ds_mode_ndc, by = "ndc11") |>
  mutate(days_supply_fixed = !between(days_supply, 3, 90),
         days_supply = if_else(days_supply_fixed, coalesce(ds_typical, ds_typical_ndc), days_supply)) |>
  select(-ds_typical, -ds_typical_ndc)

stopifnot(all(!is.na(pharmacy_clean$product_name)))   # every NDC matched the lookup
saveRDS(pharmacy_clean, file.path(dir_derived, "pharmacy_clean.rds"))
message("Pharmacy: ", nrow(pharmacy), " raw rows -> ", nrow(pharmacy_clean), " clean paid claims; ",
        sum(pharmacy_clean$days_supply_fixed), " days-supply values corrected")
```

**What**

- Standardize diagnosis codes (`clean_dx()`: upper case, no dot) and pad place of service to two characters (`str_pad()`).
- Remove duplicate lines (`distinct()`, then one row per `claim_id` + `line_num`).
- Back-calculate missing allowed amounts from paid amounts using the median paid/allowed ratio by claim type (`paid_ratio`).

**Why.** Consistent codes make the code lists work, and duplicate lines would double-count utilization and costs.


``` r
medical <- readRDS(file.path(dir_derived, "raw_medical.rds"))

clean_dx <- function(x) gsub(".", "", toupper(trimws(x)), fixed = TRUE)

medical_clean <- medical |>
  mutate(across(dx1:dx5, clean_dx),
         place_of_service = stringr::str_pad(place_of_service, 2, side = "left", pad = "0"),
         proc_code = toupper(proc_code)) |>
  distinct() |>                                     # exact duplicates (incl. after normalization)
  distinct(claim_id, line_num, .keep_all = TRUE)    # one row per claim line

# Missing allowed amounts: back-calculate from paid using the typical paid/allowed ratio
paid_ratio <- medical_clean |>
  filter(allowed_amt > 0) |>
  group_by(claim_type) |>
  summarise(ratio = median(paid_amt / allowed_amt), .groups = "drop")
medical_clean <- medical_clean |>
  left_join(paid_ratio, by = "claim_type") |>
  mutate(allowed_imputed = is.na(allowed_amt),
         allowed_amt = if_else(allowed_imputed, round(paid_amt / ratio, 2), allowed_amt)) |>
  select(-ratio)

saveRDS(medical_clean, file.path(dir_derived, "medical_clean.rds"))
message("Medical: ", nrow(medical), " raw lines -> ", nrow(medical_clean), " clean lines; ",
        sum(medical_clean$allowed_imputed), " allowed amounts imputed")
```

# Step 6. Build the cohort (with a flow diagram)

**What**

- Load the clean tables and build a long diagnosis table, one row per member, date and code (`pivot_longer(dx1:dx5)`).

**Why.** Searching one column is simpler and faster than searching five.


``` r
members  <- readRDS(file.path(dir_derived, "members_clean.rds"))
spans    <- readRDS(file.path(dir_derived, "enrollment_spans.rds"))
segments <- readRDS(file.path(dir_derived, "enrollment_segments.rds"))
rx       <- readRDS(file.path(dir_derived, "pharmacy_clean.rds"))
med      <- readRDS(file.path(dir_derived, "medical_clean.rds"))

# Long diagnosis table: one row per member, date and diagnosis code (any position dx1-dx5)
dx_long <- med |>
  select(member_id, service_from_date, dx1:dx5) |>
  tidyr::pivot_longer(dx1:dx5, values_to = "dx", values_drop_na = TRUE) |>
  distinct(member_id, date = service_from_date, dx)
saveRDS(dx_long, file.path(dir_derived, "dx_long.rds"))
```

**What**

- Define the code lists: study products, all GLP-1 RA products, obesity (`dx_obesity`), diabetes (`dx_diabetes`), contraindications (`dx_contraind`) and non-metformin antidiabetic drug classes.
- Write a helper, `has_dx()`, that returns TRUE if a member has a matching code between two dates.

**Why.** Code lists written in one place are easy to review against the SAP and reuse.


``` r
# Code lists (ICD-10-CM without decimal point; regular expressions on the start of the code)
study_products  <- c(ZEPBOUND = "Tirzepatide", WEGOVY = "Semaglutide 2.4 mg")
glp1_products   <- c("ZEPBOUND", "WEGOVY", "MOUNJARO", "OZEMPIC", "RYBELSUS", "SAXENDA")
dx_obesity      <- "^E66(0|1|2|8|9)|^Z68(3|4)"   # E66.x except E66.3 overweight; BMI >= 30
dx_diabetes     <- "^E1[01]"                     # type 1 (E10) or type 2 (E11) diabetes
dx_contraind    <- "^C73|^E3122"                 # thyroid cancer / MEN 2 (boxed warning)
antidiabetic_classes <- c("SGLT2 INHIBITOR", "SULFONYLUREA", "INSULIN, LONG-ACTING", "DPP-4 INHIBITOR")

# helper: does a member have a code matching `pattern` between two dates?
has_dx <- function(ids, from, to, pattern) {
  hits <- dx_long |> filter(grepl(pattern, dx)) |> select(member_id, date)
  tibble(member_id = ids, from = from, to = to) |>
    left_join(hits, by = "member_id", relationship = "many-to-many") |>
    group_by(member_id) |>
    summarise(flag = any(!is.na(date) & date >= from & date <= to), .groups = "drop") |>
    pull(flag, name = member_id) |> (\(x) x[ids])()
}
```

**What**

- Find each member's first Zepbound or Wegovy fill in January 2024 to June 2025: this is the index date and sets the treatment group (`summarise(index_date = first(fill_date))`).
- Record the counts at each step with `add_step()`.

**Why.** In the target trial emulation, the first fill is "time zero": eligibility, treatment assignment and the start of follow-up all happen on the same day, which avoids immortal time bias.


``` r
attrition <- list()
add_step <- function(step, data) {
  attrition[[length(attrition) + 1]] <<- tibble(
    step = step, n = nrow(data),
    n_tirzepatide = sum(data$drug == "Tirzepatide"),
    n_semaglutide = sum(data$drug == "Semaglutide 2.4 mg"))
  data
}

study_fills <- rx |> filter(product_name %in% names(study_products))

# Index = first Zepbound or Wegovy fill within the identification window
index <- study_fills |>
  filter(fill_date >= index_start, fill_date <= index_end) |>
  arrange(member_id, fill_date) |>
  group_by(member_id) |>
  summarise(index_date = first(fill_date),
            n_products_on_index = n_distinct(product_name[fill_date == first(fill_date)]),
            index_product = first(product_name), .groups = "drop") |>
  mutate(drug = factor(study_products[index_product], levels = c("Semaglutide 2.4 mg", "Tirzepatide")))

cohort <- add_step("1. First Zepbound or Wegovy fill, Jan 2024 - Jun 2025 (index date)", index)
```

**What.** Apply the criteria in SAP order, recording counts after each `filter()` / `semi_join()` / `anti_join()`:

1. one study drug on the index date;
2. age 18-64;
3. known sex and no conflicting records;
4. continuous enrollment (`span_start <= index_date - 365`, `span_end >= index_date + 364`);
5. no GLP-1 RA fill in the 365-day baseline (new user);
6. obesity diagnosis;
7. no diabetes (no E10/E11 code and no non-metformin antidiabetic fill);
8. no thyroid cancer / MEN 2 code.

**Why.** Each criterion puts into practice an element of the PECO question and the target trial. The new-user washout makes the two groups comparable at the start of treatment.


``` r
cohort <- cohort |>
  filter(n_products_on_index == 1) |>
  add_step("2. Only one study drug filled on the index date", data = _)

cohort <- cohort |>
  left_join(members, by = "member_id") |>
  mutate(age = lubridate::year(index_date) - birth_year) |>
  filter(!is.na(age), age >= 18, age <= 64) |>
  add_step("3. Aged 18-64 at index (birth year recorded)", data = _)

cohort <- cohort |>
  filter(!demo_conflict, sex %in% c("F", "M")) |>
  add_step("4. Known sex and no conflicting member records", data = _)

cont_enrolled <- spans |>
  inner_join(cohort |> select(member_id, index_date), by = "member_id") |>
  filter(span_start <= index_date - baseline_days, span_end >= index_date + followup_days - 1) |>
  distinct(member_id)
cohort <- cohort |>
  semi_join(cont_enrolled, by = "member_id") |>
  add_step("5. Continuous medical + pharmacy enrollment 365 days before and after index", data = _)

prior_glp1 <- rx |>
  filter(product_name %in% glp1_products) |>
  inner_join(cohort |> select(member_id, index_date), by = "member_id") |>
  filter(fill_date >= index_date - baseline_days, fill_date < index_date) |>
  distinct(member_id)
cohort <- cohort |>
  anti_join(prior_glp1, by = "member_id") |>
  add_step("6. New user: no GLP-1 RA fill (any product) in the 365-day baseline", data = _)

cohort <- cohort |>
  filter(has_dx(member_id, index_date - baseline_days, index_date, dx_obesity)) |>
  add_step("7. Obesity diagnosis (E66 excl. E66.3, or BMI Z68.30-Z68.45) in baseline or on index", data = _)

baseline_antidiabetic <- rx |>
  filter(therapeutic_class %in% antidiabetic_classes) |>
  inner_join(cohort |> select(member_id, index_date), by = "member_id") |>
  filter(fill_date >= index_date - baseline_days, fill_date <= index_date) |>
  distinct(member_id)
cohort <- cohort |>
  filter(!has_dx(member_id, index_date - baseline_days, index_date, dx_diabetes)) |>
  anti_join(baseline_antidiabetic, by = "member_id") |>
  add_step("8. No diabetes (no E10/E11 diagnosis, no non-metformin antidiabetic drug) in baseline", data = _)

cohort <- cohort |>
  filter(!has_dx(member_id, index_date - baseline_days, index_date, dx_contraind)) |>
  add_step("9. No medullary thyroid cancer / MEN 2 risk code (C73, E31.22) in baseline", data = _)
```

**What.** Add plan type and employer group from the enrollment segment covering the index date (`eligibility_start <= index_date`, `eligibility_end >= index_date`), add the index quarter, and save `cohort.rds`.

**Why.** Plan type is a confounder (benefit design and cost sharing). Index quarter captures calendar-time changes in supply and coverage.


``` r
# Plan type and employer group from the enrollment segment covering the index date
plan_at_index <- segments |>
  inner_join(cohort |> select(member_id, index_date), by = "member_id") |>
  filter(eligibility_start <= index_date, eligibility_end >= index_date) |>
  arrange(member_id, desc(eligibility_start)) |>
  distinct(member_id, .keep_all = TRUE) |>
  select(member_id, plan_type, group_id)

cohort <- cohort |>
  left_join(plan_at_index, by = "member_id") |>
  mutate(index_qtr = paste0(lubridate::year(index_date), "Q", lubridate::quarter(index_date)),
         treat = as.integer(drug == "Tirzepatide")) |>
  select(member_id, index_date, index_qtr, drug, treat, age, sex, state, region, plan_type, group_id)
stopifnot(!anyNA(cohort$plan_type), !anyDuplicated(cohort$member_id))
saveRDS(cohort, file.path(dir_derived, "cohort.rds"))
```

**What.** Save the attrition table and draw the flow diagram (Figure 1) with ggplot2.

**Why.** The flow diagram is required by RECORD-PE and shows readers how the study population was reached.


``` r
attrition_tbl <- bind_rows(attrition) |>
  mutate(excluded = lag(n) - n)
readr::write_csv(attrition_tbl, file.path(dir_tables, "attrition.csv"))
print(attrition_tbl, width = 200)
```

```
## # A tibble: 9 × 5
##   step                                                                          
##   <chr>                                                                         
## 1 1. First Zepbound or Wegovy fill, Jan 2024 - Jun 2025 (index date)            
## 2 2. Only one study drug filled on the index date                               
## 3 3. Aged 18-64 at index (birth year recorded)                                  
## 4 4. Known sex and no conflicting member records                                
## 5 5. Continuous medical + pharmacy enrollment 365 days before and after index   
## 6 6. New user: no GLP-1 RA fill (any product) in the 365-day baseline           
## 7 7. Obesity diagnosis (E66 excl. E66.3, or BMI Z68.30-Z68.45) in baseline or o…
## 8 8. No diabetes (no E10/E11 diagnosis, no non-metformin antidiabetic drug) in …
## 9 9. No medullary thyroid cancer / MEN 2 risk code (C73, E31.22) in baseline    
##       n n_tirzepatide n_semaglutide excluded
##   <int>         <int>         <int>    <int>
## 1 10540          4902          5638       NA
## 2 10512          4889          5623       28
## 3  9970          4658          5312      542
## 4  9911          4631          5280       59
## 5  7469          3504          3965     2442
## 6  6637          3242          3395      832
## 7  5660          2763          2897      977
## 8  5251          2561          2690      409
## 9  5240          2558          2682       11
```

``` r
# Flow diagram (Figure 1)
flow <- attrition_tbl |>
  mutate(y = rev(seq_len(n())),
         label = paste0(step, "\nN = ", scales::comma(n),
                        "  (tirzepatide ", scales::comma(n_tirzepatide),
                        "; semaglutide ", scales::comma(n_semaglutide), ")"),
         excl  = ifelse(is.na(excluded), NA, paste0("Excluded: ", scales::comma(excluded))))
p_flow <- ggplot(flow, aes(x = 0, y = y)) +
  geom_segment(data = flow[-1, ], aes(x = 0, xend = 0, y = y + 0.62, yend = y + 0.38),
               arrow = arrow(length = unit(2, "mm"))) +
  geom_label(aes(label = label), size = 2.7, linewidth = 0.3, fill = "white", hjust = 0.5) +
  geom_text(aes(x = 0.9, y = y + 0.5, label = excl), size = 2.6, hjust = 0, colour = "grey30", na.rm = TRUE) +
  scale_x_continuous(limits = c(-1.1, 1.3)) +
  theme_void() +
  labs(title = "Figure 1. Cohort selection (synthetic commercial claims, 2023-2026)")
ggsave(file.path(dir_figures, "fig1_cohort_flow.png"), p_flow, width = 9, height = 8, dpi = 200, bg = "white")
```

# Step 7. Baseline covariates

**What.** Load the cohort and claims, and compute each claim's day relative to the index date (`day = fill_date - index_date`).

**Why.** Working in "days since index" makes every time window a simple filter (e.g., baseline = `day >= -365 & day <= -1`).


``` r
cohort  <- readRDS(file.path(dir_derived, "cohort.rds"))
rx      <- readRDS(file.path(dir_derived, "pharmacy_clean.rds"))
med     <- readRDS(file.path(dir_derived, "medical_clean.rds"))
dx_long <- readRDS(file.path(dir_derived, "dx_long.rds"))

ids <- cohort |> select(member_id, index_date)
# Keep only cohort members' claims, with each claim's day relative to index (0 = index date)
rx_c  <- rx  |> inner_join(ids, by = "member_id") |> mutate(day = as.integer(fill_date - index_date))
med_c <- med |> inner_join(ids, by = "member_id") |> mutate(day = as.integer(service_from_date - index_date))
dx_c  <- dx_long |> inner_join(ids, by = "member_id") |> mutate(day = as.integer(date - index_date))
```

**What**

- Define encounters once, one per member per day: inpatient admissions (`claim_type == "INST"` with an admission date), ED visits (place of service 23, revenue code 0450 or CPT 99281-99285), outpatient E/M visits, and obesity-related outpatient visits (E66/Z68 on the claim).
- Sum medical costs by claim and floor each claim at $0 (`max(0, sum(allowed_amt))`).

**Why.** The same definitions are used for baseline covariates (here) and follow-up outcomes (Step 8), so the two are measured consistently.


``` r
# Encounter types used for baseline AND follow-up utilization (one visit per member per day)
em_outpatient <- c(sprintf("%d", c(99202:99205, 99211:99215, 99381:99397)), "G0438")
encounters <- bind_rows(
  med_c |> filter(claim_type == "INST", !is.na(admit_date)) |>
    distinct(member_id, day = as.integer(admit_date - index_date)) |> mutate(type = "inpatient"),
  med_c |> filter((claim_type == "INST" & place_of_service == "23") | revenue_code %in% "0450" |
                    proc_code %in% as.character(99281:99285)) |>
    distinct(member_id, day) |> mutate(type = "ed"),
  med_c |> filter(claim_type == "PROF", proc_code %in% em_outpatient,
                  place_of_service %in% c("02", "10", "11", "19", "22")) |>
    distinct(member_id, day) |> mutate(type = "outpatient"),
  med_c |> filter(claim_type == "PROF", proc_code %in% em_outpatient,
                  place_of_service %in% c("02", "10", "11", "19", "22"),
                  if_any(dx1:dx5, ~ grepl("^E66|^Z68", .x))) |>
    distinct(member_id, day) |> mutate(type = "outpatient_obesity")
)
saveRDS(encounters, file.path(dir_derived, "encounters.rds"))

# Claim-level medical costs: adjustment lines net against their claim; floor at $0
med_claims <- med_c |>
  group_by(member_id, claim_id) |>
  summarise(day = min(day), allowed = max(0, sum(allowed_amt)), .groups = "drop")
saveRDS(med_claims, file.path(dir_derived, "med_claims.rds"))
```

**What**

- Flag comorbidities from codes in [index - 365, index] with `dx_flag()` (e.g., hypertension `^I1[0-6]`, sleep apnea `^G4733`).
- Assign obesity class from the most recent BMI or class code (`case_when()`; Class 3 = BMI >= 40, E66.01, E66.2 or E66.813).

**Why.** These are the confounders in the DAG: they influence which drug is prescribed and the outcomes.


``` r
# Diagnosis flags: any code in [index - 365, index]
dx_base <- dx_c |> filter(day >= -baseline_days, day <= 0)
dx_flag <- function(pattern) ids$member_id %in% dx_base$member_id[grepl(pattern, dx_base$dx)]
comorb <- tibble(
  member_id     = ids$member_id,
  hypertension  = dx_flag("^I1[0-6]"),
  dyslipidemia  = dx_flag("^E78"),
  sleep_apnea   = dx_flag("^G4733"),
  prediabetes   = dx_flag("^R730"),
  masld         = dx_flag("^K760|^K7581"),
  osteoarthritis = dx_flag("^M1[5-9]"),
  depression    = dx_flag("^F3[23]"),
  anxiety       = dx_flag("^F41"),
  gerd          = dx_flag("^K21"),
  ascvd         = dx_flag("^I2[0-5]|^I63|^I73|^Z8673"),
  heart_failure = dx_flag("^I50"),
  ckd           = dx_flag("^N18"),
  pcos          = dx_flag("^E282"),
  hypothyroid   = dx_flag("^E03"),
  gallbladder   = dx_flag("^K80"),
  pancreatitis  = dx_flag("^K8[56]")
)

# Obesity class from the most recent BMI or class-specific code in baseline
obesity_class <- dx_base |>
  mutate(cls = case_when(
    grepl("^Z68(4[1-5])|^E66813|^E6601|^E662", dx) ~ 3L,
    grepl("^Z683[5-9]|^E66812", dx)                ~ 2L,
    grepl("^Z683[0-4]|^E66811", dx)                ~ 1L)) |>
  filter(!is.na(cls)) |>
  group_by(member_id) |>
  filter(day == max(day)) |>
  summarise(cls = max(cls), .groups = "drop")
```

**What.** Baseline utilization and costs: counts of each encounter type (`count(member_id, type)`), baseline medical and pharmacy costs, number of distinct generic drugs, endocrinologist visit, and prior bariatric surgery.

**Why.** Prior healthcare use is the best available proxy for overall health and care-seeking, which affect both drug choice and future costs.


``` r
# Baseline utilization and costs: [index - 365, index - 1]
base_enc <- encounters |>
  filter(day >= -baseline_days, day <= -1) |>
  count(member_id, type) |>
  tidyr::pivot_wider(names_from = type, values_from = n, values_fill = 0)
base_med_cost <- med_claims |> filter(day >= -baseline_days, day <= -1) |>
  group_by(member_id) |> summarise(base_med_cost = sum(allowed))
base_rx_cost  <- rx_c |> filter(day >= -baseline_days, day <= -1) |>
  group_by(member_id) |> summarise(base_rx_cost = sum(allowed_amt), n_generics = n_distinct(generic_name))
endo_visit    <- med_c |> filter(day >= -baseline_days, day <= -1, prov_specialty == "END") |> distinct(member_id)
bariatric     <- union(
  dx_base$member_id[grepl("^Z9884", dx_base$dx)],
  med_c$member_id[med_c$proc_code %in% c("43644", "43775") & med_c$day < 0 & med_c$day >= -baseline_days])
```

**What.** Baseline medication flags by therapeutic class with `rx_flag()` (other anti-obesity drugs, metformin, antihypertensives, statins, antidepressants).

**Why.** Medication use marks comorbidity severity and treatment history.


``` r
rx_base <- rx_c |> filter(day >= -baseline_days, day <= -1)
rx_flag <- function(classes) ids$member_id %in% rx_base$member_id[rx_base$therapeutic_class %in% classes]
meds <- tibble(
  member_id         = ids$member_id,
  prior_aom         = rx_flag(c("ANOREXIGENIC AGENT", "ANTI-OBESITY AGENT")),
  metformin         = rx_flag("BIGUANIDE"),
  antihypertensive  = rx_flag(c("ACE INHIBITOR", "ANGIOTENSIN II RECEPTOR BLOCKER", "CALCIUM CHANNEL BLOCKER",
                                "BETA BLOCKER", "LOOP DIURETIC", "ALDOSTERONE ANTAGONIST")),
  statin            = rx_flag("HMG-COA REDUCTASE INHIBITOR"),
  antidepressant    = rx_flag(c("SSRI", "ANTIDEPRESSANT, OTHER"))
)
```

**What.** Join everything into one row per patient; create factors (obesity class, age group, CDHP vs non-CDHP), any baseline inpatient/ED use, and `log_base_cost = log1p(base_total_cost)`; save `covariates.rds`.

**Why.** The log of baseline cost reduces the influence of a few very expensive patients in the propensity score model.


``` r
covariates <- cohort |>
  left_join(comorb, by = "member_id") |>
  left_join(meds, by = "member_id") |>
  left_join(obesity_class, by = "member_id") |>
  left_join(base_enc, by = "member_id") |>
  left_join(base_med_cost, by = "member_id") |>
  left_join(base_rx_cost, by = "member_id") |>
  mutate(
    across(c(inpatient, ed, outpatient, outpatient_obesity, base_med_cost, base_rx_cost, n_generics),
           ~ coalesce(.x, 0)),
    obesity_class   = factor(coalesce(c("Class 1", "Class 2", "Class 3")[cls], "Unknown"),
                             levels = c("Class 1", "Class 2", "Class 3", "Unknown")),
    age_group       = factor(ifelse(age < 45, "18-44", "45-64")),
    sex             = factor(sex, levels = c("F", "M"), labels = c("Female", "Male")),
    region          = factor(region),
    plan_type       = factor(plan_type, levels = c("PPO", "HMO", "POS", "EPO", "CDHP")),
    cdhp            = factor(ifelse(plan_type == "CDHP", "CDHP", "Non-CDHP"), levels = c("Non-CDHP", "CDHP")),
    index_qtr       = factor(index_qtr),
    endo_visit      = member_id %in% endo_visit$member_id,
    bariatric_hx    = member_id %in% bariatric,
    base_any_ip     = inpatient > 0,
    base_any_ed     = ed > 0,
    base_op_visits  = outpatient,
    base_total_cost = base_med_cost + base_rx_cost,
    log_base_cost   = log1p(base_total_cost)
  ) |>
  select(-cls, -inpatient, -ed, -outpatient, -outpatient_obesity)
stopifnot(nrow(covariates) == nrow(cohort))
saveRDS(covariates, file.path(dir_derived, "covariates.rds"))
glimpse(covariates)
```

```
## Rows: 5,240
## Columns: 45
## $ member_id        <chr> "PT10001205", "PT10051824", "PT10053973", "PT10061145…
## $ index_date       <date> 2025-04-18, 2025-05-04, 2024-08-25, 2024-07-27, 2024…
## $ index_qtr        <fct> 2025Q2, 2025Q2, 2024Q3, 2024Q3, 2024Q4, 2025Q2, 2024Q…
## $ drug             <fct> Semaglutide 2.4 mg, Tirzepatide, Semaglutide 2.4 mg, …
## $ treat            <int> 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1,…
## $ age              <dbl> 50, 58, 33, 46, 58, 43, 48, 38, 61, 41, 43, 48, 42, 3…
## $ sex              <fct> Female, Female, Female, Male, Male, Male, Female, Fem…
## $ state            <chr> "WY", "HI", "MD", "OR", "MA", "CT", "FL", "LA", "NY",…
## $ region           <fct> West, West, South, West, Northeast, Northeast, South,…
## $ plan_type        <fct> EPO, HMO, HMO, PPO, PPO, PPO, HMO, PPO, PPO, CDHP, HM…
## $ group_id         <chr> "G100190", "G100142", "G100104", "G100253", "G100348"…
## $ hypertension     <lgl> TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, …
## $ dyslipidemia     <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, TRUE, …
## $ sleep_apnea      <lgl> FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE,…
## $ prediabetes      <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE…
## $ masld            <lgl> FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE…
## $ osteoarthritis   <lgl> FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE,…
## $ depression       <lgl> FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, …
## $ anxiety          <lgl> TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, TRUE, TRUE, FA…
## $ gerd             <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE…
## $ ascvd            <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE,…
## $ heart_failure    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
## $ ckd              <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
## $ pcos             <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
## $ hypothyroid      <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE,…
## $ gallbladder      <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
## $ pancreatitis     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
## $ prior_aom        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
## $ metformin        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE…
## $ antihypertensive <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE,…
## $ statin           <lgl> TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, TRUE, …
## $ antidepressant   <lgl> FALSE, FALSE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE, F…
## $ base_med_cost    <dbl> 311.71, 4121.74, 1236.57, 878.08, 13005.98, 270.86, 2…
## $ base_rx_cost     <dbl> 127.60, 0.00, 64.93, 100.25, 282.09, 164.68, 210.83, …
## $ n_generics       <dbl> 2, 0, 1, 2, 3, 3, 5, 3, 0, 1, 2, 3, 0, 2, 1, 1, 1, 0,…
## $ obesity_class    <fct> Unknown, Class 1, Class 2, Class 2, Class 1, Class 3,…
## $ age_group        <fct> 45-64, 45-64, 18-44, 45-64, 45-64, 18-44, 45-64, 18-4…
## $ cdhp             <fct> Non-CDHP, Non-CDHP, Non-CDHP, Non-CDHP, Non-CDHP, Non…
## $ endo_visit       <lgl> FALSE, FALSE, FALSE, TRUE, FALSE, TRUE, TRUE, FALSE, …
## $ bariatric_hx     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
## $ base_any_ip      <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE…
## $ base_any_ed      <lgl> FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, …
## $ base_op_visits   <dbl> 2, 4, 2, 5, 6, 2, 8, 4, 4, 2, 2, 3, 6, 6, 2, 1, 3, 3,…
## $ base_total_cost  <dbl> 439.31, 4121.74, 1301.50, 978.33, 13288.07, 435.54, 2…
## $ log_base_cost    <dbl> 6.087479, 8.324273, 7.172041, 6.886869, 9.494697, 6.0…
```

# Step 8. Outcomes over the 365-day follow-up

**What.** Load data; keep follow-up fills (days 0-364) of either molecule, labelled by molecule (Zepbound/Mounjaro = tirzepatide; Wegovy/Ozempic/Rybelsus = semaglutide).

**Why.** Persistence is measured on the index molecule, and fills of the other molecule mark switching.


``` r
covariates <- readRDS(file.path(dir_derived, "covariates.rds"))
rx         <- readRDS(file.path(dir_derived, "pharmacy_clean.rds"))
encounters <- readRDS(file.path(dir_derived, "encounters.rds"))
med_claims <- readRDS(file.path(dir_derived, "med_claims.rds"))
med        <- readRDS(file.path(dir_derived, "medical_clean.rds"))

ids <- covariates |> select(member_id, index_date, drug)
fu_last <- followup_days - 1   # follow-up runs from day 0 (index) to day 364

# Follow-up fills of tirzepatide or semaglutide (any brand) with the day relative to index
molecule <- c(ZEPBOUND = "Tirzepatide", MOUNJARO = "Tirzepatide",
              WEGOVY = "Semaglutide 2.4 mg", OZEMPIC = "Semaglutide 2.4 mg", RYBELSUS = "Semaglutide 2.4 mg")
fu_fills <- rx |>
  filter(product_name %in% names(molecule)) |>
  inner_join(ids, by = "member_id") |>
  mutate(day = as.integer(fill_date - index_date), fill_molecule = molecule[product_name]) |>
  filter(day >= 0, day <= fu_last) |>
  arrange(member_id, day)
```

**What.** Write the persistence function `persistence(day, ds, gap)`:

- `start`/`end` lay the fills end to end, carrying early refills forward;
- `gaps_before` and `tail_gap` measure days without supply;
- the first gap longer than `gap` days is a discontinuation (`disc_day`);
- `pdc` = days covered / 365.

**Why.** This is the standard claims definition of persistence (no refill gap > 60 days) and adherence (proportion of days covered), as used by Marshall 2026. Writing it as a function lets us change the gap for the sensitivity analyses.


``` r
# Persistence for one patient's fills of a drug.
# - Early refills are carried over: a fill's supply starts the day after the previous supply ends.
# - Discontinuation = first gap of more than `gap` days without supply (including the gap
#   between the last supply and the end of follow-up). Event day = first uncovered day.
# - PDC = days covered in the 365-day follow-up / 365.
persistence <- function(day, ds, gap = 60, last = 364) {
  n <- length(day); start <- end <- integer(n)
  for (k in seq_len(n)) {
    start[k] <- if (k == 1) day[k] else max(day[k], end[k - 1] + 1L)
    end[k]   <- start[k] + ds[k] - 1L
  }
  gaps_before <- c(0L, start[-1] - end[-n] - 1L)          # gap before each refill
  tail_gap    <- last - end[n]                            # gap after the last supply
  k_gap <- which(gaps_before > gap)[1]
  disc_day <- if (!is.na(k_gap)) end[k_gap - 1] + 1L else if (tail_gap > gap) end[n] + 1L else NA_integer_
  covered  <- sum(pmax(0L, pmin(end, last) - pmin(start, last + 1L) + 1L))
  tibble(persistent = is.na(disc_day),
         time_to_disc = if (is.na(disc_day)) as.integer(last + 1) else min(disc_day, last + 1L),
         pdc = covered / (last + 1))
}
```

**What.** Apply the function to each patient (`group_by(member_id) |> reframe(persistence(...))`) with gaps of 60 (primary), 30 and 90 days, and on either molecule (`p_class`). Flag switching to the other molecule (`switching`).

**Why.** The primary outcome and sensitivity analyses S1-S3 come from the same function, so only the definition changes.


``` r
index_fills <- fu_fills |> filter(fill_molecule == drug)   # the index molecule only

persist_all <- function(fills, gap) {
  fills |>
    group_by(member_id) |>
    reframe(persistence(day, days_supply, gap = gap, last = fu_last))
}
p60 <- persist_all(index_fills, 60)
p30 <- persist_all(index_fills, 30) |> rename_with(~ paste0(.x, "_g30"), -member_id)
p90 <- persist_all(index_fills, 90) |> rename_with(~ paste0(.x, "_g90"), -member_id)
# Sensitivity: persistence on EITHER molecule (switching between them is not discontinuation)
p_class <- persist_all(fu_fills, 60) |>
  select(member_id, persistent_class = persistent, time_to_disc_class = time_to_disc)

switching <- fu_fills |>
  filter(fill_molecule != drug) |>
  group_by(member_id) |>
  summarise(switched = TRUE, switch_day = min(day))
```

**What.** Count follow-up encounters by type, and sum 12-month medical, pharmacy, study-drug and out-of-pocket costs. Flag the negative control outcome (colonoscopy 45378 or screening mammogram 77067).

**Why.** These are the Aim 3 and 4 outcomes. The negative control outcome checks for residual confounding by healthcare-seeking behaviour.


``` r
fu_enc <- encounters |>
  filter(day >= 0, day <= fu_last) |>
  count(member_id, type) |>
  tidyr::pivot_wider(names_from = type, values_from = n, values_fill = 0, names_prefix = "n_")

fu_med_cost <- med_claims |> filter(day >= 0, day <= fu_last) |>
  group_by(member_id) |> summarise(cost_medical = sum(allowed))
fu_rx_cost  <- rx |> inner_join(ids, by = "member_id") |>
  mutate(day = as.integer(fill_date - index_date)) |>
  filter(day >= 0, day <= fu_last) |>
  group_by(member_id) |>
  summarise(cost_pharmacy = sum(allowed_amt),
            cost_study_drug = sum(allowed_amt[product_name %in% c("ZEPBOUND", "WEGOVY")]),
            oop_study_drug  = sum(member_oop[product_name %in% c("ZEPBOUND", "WEGOVY")]))

# Negative control outcome: routine cancer screening (colonoscopy 45378, screening mammogram 77067)
neg_control <- med |> filter(proc_code %in% c("45378", "77067")) |>
  inner_join(ids, by = "member_id") |>
  mutate(day = as.integer(service_from_date - index_date)) |>
  filter(day >= 0, day <= fu_last) |>
  distinct(member_id) |> mutate(neg_control = TRUE)
```

**What.** Join all outcomes, fill zeros for patients with no encounters (`coalesce(.x, 0)`), create binary outcomes (`pdc80`, `any_ip`, `any_ed`) and total cost; save `analytic.rds`; print a crude (unweighted) summary by drug.

**Why.** One analytic dataset with one row per patient feeds every model. The crude summary is a first look before adjustment.


``` r
outcomes <- ids |>
  select(member_id) |>
  left_join(p60, by = "member_id") |> left_join(p30, by = "member_id") |> left_join(p90, by = "member_id") |>
  left_join(p_class, by = "member_id") |> left_join(switching, by = "member_id") |>
  left_join(fu_enc, by = "member_id") |> left_join(fu_med_cost, by = "member_id") |>
  left_join(fu_rx_cost, by = "member_id") |> left_join(neg_control, by = "member_id") |>
  mutate(
    across(c(switched, neg_control), ~ coalesce(.x, FALSE)),
    across(c(n_inpatient, n_ed, n_outpatient, n_outpatient_obesity, cost_medical), ~ coalesce(.x, 0)),
    discontinued = !persistent,
    pdc80        = pdc >= 0.80,
    any_ip       = n_inpatient > 0,
    any_ed       = n_ed > 0,
    cost_total   = cost_medical + cost_pharmacy
  )
stopifnot(nrow(outcomes) == nrow(ids), !anyNA(outcomes$persistent), all(outcomes$cost_pharmacy > 0))
saveRDS(outcomes, file.path(dir_derived, "outcomes.rds"))

analytic <- covariates |> left_join(outcomes, by = "member_id")
saveRDS(analytic, file.path(dir_derived, "analytic.rds"))

# Crude (unweighted) outcome summary by drug
analytic |>
  group_by(drug) |>
  summarise(n = n(), persistent_12m = mean(persistent), mean_pdc = mean(pdc), pdc80 = mean(pdc80),
            switched = mean(switched), any_ip = mean(any_ip), any_ed = mean(any_ed),
            op_visits = mean(n_outpatient), cost_medical = mean(cost_medical),
            cost_pharmacy = mean(cost_pharmacy), cost_total = mean(cost_total)) |>
  print(width = 200)
```

```
## # A tibble: 2 × 12
##   drug                   n persistent_12m mean_pdc pdc80 switched any_ip any_ed
##   <fct>              <int>          <dbl>    <dbl> <dbl>    <dbl>  <dbl>  <dbl>
## 1 Semaglutide 2.4 mg  2682          0.511    0.605 0.405   0.0880 0.0488  0.255
## 2 Tirzepatide         2558          0.579    0.640 0.457   0.0227 0.0395  0.224
##   op_visits cost_medical cost_pharmacy cost_total
##       <dbl>        <dbl>         <dbl>      <dbl>
## 1      6.10        4370.        11231.     15602.
## 2      5.26        4317.         9401.     13717.
```

# Step 9. Table 1, propensity score and weighting

**What.** Load the analytic file and write the propensity score formula from the DAG adjustment set (`covs`, `reformulate(covs, response = "treat")`).

**Why.** The PS model includes the confounders and nothing measured after the index date.


``` r
analytic <- readRDS(file.path(dir_derived, "analytic.rds"))

# Adjustment set from the DAG (SAP section 7)
covs <- c("age", "sex", "region", "plan_type", "index_qtr", "obesity_class",
          "hypertension", "dyslipidemia", "sleep_apnea", "prediabetes", "masld", "osteoarthritis",
          "depression", "anxiety", "gerd", "ascvd", "heart_failure", "ckd", "pcos", "hypothyroid",
          "gallbladder", "pancreatitis", "prior_aom", "metformin", "antihypertensive", "statin",
          "antidepressant", "n_generics", "bariatric_hx", "endo_visit", "base_any_ip", "base_any_ed",
          "base_op_visits", "log_base_cost")
ps_formula <- reformulate(covs, response = "treat")
```

**What.** Fit a logistic propensity score model and compute stabilized ATE weights with `WeightIt::weightit(..., method = "glm", estimand = "ATE", stabilize = TRUE)`; save the weights.

**Why.** Inverse probability of treatment weighting creates a pseudo-population in which measured confounders are balanced between the drugs, as in a randomized trial. Stabilization keeps the weights near 1.


``` r
# Propensity score (logistic regression) and stabilized ATE weights
w_ate <- WeightIt::weightit(ps_formula, data = analytic, method = "glm",
                            estimand = "ATE", stabilize = TRUE)
summary(w_ate)
```

```
##                   Summary of weights
## 
## - Weight ranges:
## 
##           Min                                 Max
## treated 0.602 |---------------------------| 6.526
## control 0.572 |-----|                       2.119
## 
## - Units with the 5 most extreme weights by group:
##                                       
##           1975   503  3298  3228  4104
##  treated 2.474 2.503 3.821 3.827 6.526
##           3324  1674  2402  4490  1700
##  control 1.935 2.032 2.034 2.084 2.119
## 
## - Weight statistics:
## 
##         Coef of Var   MAD Entropy # Zeros
## treated       0.277 0.182   0.031       0
## control       0.221 0.171   0.023       0
## 
## - Effective Sample Sizes:
## 
##            Control Treated
## Unweighted 2682.   2558.  
## Weighted   2557.58 2376.12
```

``` r
analytic$ps <- w_ate$ps
analytic$w  <- w_ate$weights
saveRDS(analytic, file.path(dir_derived, "analytic_weighted.rds"))
saveRDS(list(covs = covs, ps_formula = ps_formula), file.path(dir_derived, "ps_spec.rds"))
```

**What.** Check balance with `cobalt::bal.tab()`: standardized mean differences (SMD) and variance ratios before and after weighting; report the largest SMD and the effective sample size.

**Why.** Weighting only works if balance is achieved; the SAP target is |SMD| < 0.10 for every covariate.


``` r
bal <- cobalt::bal.tab(w_ate, un = TRUE, binary = "std", continuous = "std",
                       thresholds = c(m = 0.1, v = 2), stats = c("m", "v"))
print(bal)
```

```
## Balance Measures
##                           Type Diff.Un V.Ratio.Un Diff.Adj    M.Threshold
## prop.score            Distance  0.4504     0.8709  -0.0037 Balanced, <0.1
## age                    Contin. -0.1295     0.9984   0.0009 Balanced, <0.1
## sex_Male                Binary -0.0621          .  -0.0061 Balanced, <0.1
## region_Midwest          Binary  0.0089          .   0.0010 Balanced, <0.1
## region_Northeast        Binary -0.0012          .   0.0023 Balanced, <0.1
## region_South            Binary -0.0080          .  -0.0035 Balanced, <0.1
## region_Unknown          Binary -0.0343          .   0.0031 Balanced, <0.1
## region_West             Binary  0.0070          .   0.0006 Balanced, <0.1
## plan_type_PPO           Binary  0.0162          .   0.0000 Balanced, <0.1
## plan_type_HMO           Binary  0.0071          .  -0.0005 Balanced, <0.1
## plan_type_POS           Binary -0.0202          .   0.0045 Balanced, <0.1
## plan_type_EPO           Binary  0.0349          .  -0.0018 Balanced, <0.1
## plan_type_CDHP          Binary -0.0333          .  -0.0020 Balanced, <0.1
## index_qtr_2024Q1        Binary -0.1201          .  -0.0029 Balanced, <0.1
## index_qtr_2024Q2        Binary -0.1314          .   0.0031 Balanced, <0.1
## index_qtr_2024Q3        Binary -0.0061          .  -0.0002 Balanced, <0.1
## index_qtr_2024Q4        Binary  0.0222          .  -0.0015 Balanced, <0.1
## index_qtr_2025Q1        Binary  0.1351          .  -0.0000 Balanced, <0.1
## index_qtr_2025Q2        Binary  0.0997          .   0.0016 Balanced, <0.1
## obesity_class_Class 1   Binary -0.0604          .   0.0010 Balanced, <0.1
## obesity_class_Class 2   Binary  0.0381          .   0.0013 Balanced, <0.1
## obesity_class_Class 3   Binary  0.0723          .  -0.0006 Balanced, <0.1
## obesity_class_Unknown   Binary -0.0591          .  -0.0017 Balanced, <0.1
## hypertension            Binary -0.0080          .   0.0045 Balanced, <0.1
## dyslipidemia            Binary -0.0655          .   0.0020 Balanced, <0.1
## sleep_apnea             Binary  0.0824          .  -0.0021 Balanced, <0.1
## prediabetes             Binary  0.0244          .  -0.0006 Balanced, <0.1
## masld                   Binary -0.0455          .   0.0018 Balanced, <0.1
## osteoarthritis          Binary  0.0307          .  -0.0042 Balanced, <0.1
## depression              Binary  0.0021          .  -0.0002 Balanced, <0.1
## anxiety                 Binary  0.0135          .   0.0012 Balanced, <0.1
## gerd                    Binary  0.0276          .   0.0000 Balanced, <0.1
## ascvd                   Binary -0.1461          .  -0.0040 Balanced, <0.1
## heart_failure           Binary -0.0940          .   0.0078 Balanced, <0.1
## ckd                     Binary -0.0466          .   0.0052 Balanced, <0.1
## pcos                    Binary  0.0099          .   0.0043 Balanced, <0.1
## hypothyroid             Binary -0.0385          .  -0.0037 Balanced, <0.1
## gallbladder             Binary  0.0151          .  -0.0008 Balanced, <0.1
## pancreatitis            Binary  0.0088          .  -0.0007 Balanced, <0.1
## prior_aom               Binary  0.0000          .   0.0000 Balanced, <0.1
## metformin               Binary -0.0061          .  -0.0005 Balanced, <0.1
## antihypertensive        Binary -0.0058          .   0.0054 Balanced, <0.1
## statin                  Binary -0.0651          .   0.0021 Balanced, <0.1
## antidepressant          Binary  0.0035          .  -0.0010 Balanced, <0.1
## n_generics             Contin. -0.0102     1.0519   0.0012 Balanced, <0.1
## bariatric_hx            Binary -0.0067          .  -0.0039 Balanced, <0.1
## endo_visit              Binary -0.0443          .  -0.0001 Balanced, <0.1
## base_any_ip             Binary -0.0476          .  -0.0055 Balanced, <0.1
## base_any_ed             Binary -0.1142          .   0.0049 Balanced, <0.1
## base_op_visits         Contin. -0.2258     0.7461   0.0116 Balanced, <0.1
## log_base_cost          Contin. -0.1705     1.0297   0.0008 Balanced, <0.1
##                       V.Ratio.Adj  V.Threshold
## prop.score                 1.0268 Balanced, <2
## age                        1.0001 Balanced, <2
## sex_Male                        .             
## region_Midwest                  .             
## region_Northeast                .             
## region_South                    .             
## region_Unknown                  .             
## region_West                     .             
## plan_type_PPO                   .             
## plan_type_HMO                   .             
## plan_type_POS                   .             
## plan_type_EPO                   .             
## plan_type_CDHP                  .             
## index_qtr_2024Q1                .             
## index_qtr_2024Q2                .             
## index_qtr_2024Q3                .             
## index_qtr_2024Q4                .             
## index_qtr_2025Q1                .             
## index_qtr_2025Q2                .             
## obesity_class_Class 1           .             
## obesity_class_Class 2           .             
## obesity_class_Class 3           .             
## obesity_class_Unknown           .             
## hypertension                    .             
## dyslipidemia                    .             
## sleep_apnea                     .             
## prediabetes                     .             
## masld                           .             
## osteoarthritis                  .             
## depression                      .             
## anxiety                         .             
## gerd                            .             
## ascvd                           .             
## heart_failure                   .             
## ckd                             .             
## pcos                            .             
## hypothyroid                     .             
## gallbladder                     .             
## pancreatitis                    .             
## prior_aom                       .             
## metformin                       .             
## antihypertensive                .             
## statin                          .             
## antidepressant                  .             
## n_generics                 1.0760 Balanced, <2
## bariatric_hx                    .             
## endo_visit                      .             
## base_any_ip                     .             
## base_any_ed                     .             
## base_op_visits             1.1009 Balanced, <2
## log_base_cost              1.0832 Balanced, <2
## 
## Balance tally for mean differences
##                    count
## Balanced, <0.1        51
## Not Balanced, >0.1     0
## 
## Variable with the greatest mean difference
##        Variable Diff.Adj    M.Threshold
##  base_op_visits   0.0116 Balanced, <0.1
## 
## Balance tally for variance ratios
##                  count
## Balanced, <2         5
## Not Balanced, >2     0
## 
## Variable with the greatest variance ratio
##        Variable V.Ratio.Adj  V.Threshold
##  base_op_visits      1.1009 Balanced, <2
## 
## Effective sample sizes
##            Control Treated
## Unadjusted 2682.   2558.  
## Adjusted   2557.58 2376.12
```

``` r
bal_df <- bal$Balance |>
  tibble::rownames_to_column("covariate") |>
  select(covariate, smd_unweighted = Diff.Un, smd_weighted = Diff.Adj,
         var_ratio_unweighted = V.Ratio.Un, var_ratio_weighted = V.Ratio.Adj)
readr::write_csv(bal_df, file.path(dir_tables, "balance_smd.csv"))
max_smd <- max(abs(bal_df$smd_weighted), na.rm = TRUE)
message("Largest absolute weighted SMD: ", round(max_smd, 3),
        if (max_smd < 0.1) "  -> balance achieved (all < 0.10)" else "  -> IMBALANCE: revise PS model")
ess <- cobalt::bal.tab(w_ate)$Observations
print(ess)
```

```
##             Control Treated
## Unadjusted 2682.000 2558.00
## Adjusted   2557.579 2376.12
```

**What.** Build Table 1: unweighted and weighted means or percentages by group, with SMDs (`make_rows()`); save to CSV.

**Why.** Table 1 describes the study population and shows the reader that the weighted groups are comparable.


``` r
# Table 1: unweighted and IPTW-weighted characteristics with SMDs
wmean <- function(x, w) sum(x * w) / sum(w)
wsd   <- function(x, w) sqrt(sum(w * (x - wmean(x, w))^2) / sum(w))
t1_vars <- c(covs, "base_med_cost", "base_rx_cost", "base_total_cost")
make_rows <- function(v) {
  x <- analytic[[v]]
  if (is.factor(x) || is.character(x)) {
    lv <- levels(factor(x))
    purrr::map_dfr(lv, function(l) {
      ind <- as.numeric(x == l)
      tibble(variable = v, level = l, type = "pct",
             tirz = mean(ind[analytic$treat == 1]) * 100, sema = mean(ind[analytic$treat == 0]) * 100,
             tirz_w = wmean(ind[analytic$treat == 1], analytic$w[analytic$treat == 1]) * 100,
             sema_w = wmean(ind[analytic$treat == 0], analytic$w[analytic$treat == 0]) * 100,
             tirz_sd = NA, sema_sd = NA)
    })
  } else {
    x <- as.numeric(x); t1 <- analytic$treat == 1; t0 <- !t1
    tibble(variable = v, level = "", type = if (is.logical(analytic[[v]])) "pct" else "mean",
           tirz = mean(x[t1]) * if (is.logical(analytic[[v]])) 100 else 1,
           sema = mean(x[t0]) * if (is.logical(analytic[[v]])) 100 else 1,
           tirz_w = wmean(x[t1], analytic$w[t1]) * if (is.logical(analytic[[v]])) 100 else 1,
           sema_w = wmean(x[t0], analytic$w[t0]) * if (is.logical(analytic[[v]])) 100 else 1,
           tirz_sd = if (is.logical(analytic[[v]])) NA else sd(x[t1]),
           sema_sd = if (is.logical(analytic[[v]])) NA else sd(x[t0]))
  }
}
table1 <- purrr::map_dfr(t1_vars, make_rows) |>
  mutate(smd_unweighted = NA_real_, smd_weighted = NA_real_)
# attach SMDs from cobalt (names: variable, variable_TRUE or variable_level)
for (i in seq_len(nrow(table1))) {
  key <- c(paste0(table1$variable[i], "_", table1$level[i]), paste0(table1$variable[i], "_TRUE"), table1$variable[i])
  hit <- bal_df[bal_df$covariate %in% key, ]
  if (nrow(hit)) { table1$smd_unweighted[i] <- hit$smd_unweighted[1]; table1$smd_weighted[i] <- hit$smd_weighted[1] }
}
table1 <- bind_rows(
  tibble(variable = "N patients", level = "", type = "n",
         tirz = sum(analytic$treat == 1), sema = sum(analytic$treat == 0),
         tirz_w = sum(analytic$w[analytic$treat == 1]), sema_w = sum(analytic$w[analytic$treat == 0])),
  table1)
readr::write_csv(table1, file.path(dir_tables, "table1_baseline.csv"))
print(table1 |> mutate(across(where(is.numeric), ~ round(.x, 2))), n = Inf, width = 200)
```

```
## # A tibble: 55 × 11
##    variable         level       type     tirz    sema  tirz_w  sema_w  tirz_sd
##    <chr>            <chr>       <chr>   <dbl>   <dbl>   <dbl>   <dbl>    <dbl>
##  1 N patients       ""          n     2558    2682    2561.   2681.      NA   
##  2 age              ""          mean    44.2    45.5    45.0    45.0     10.4 
##  3 sex              "Female"    pct     68.6    65.7    67.4    67.1     NA   
##  4 sex              "Male"      pct     31.4    34.3    32.6    32.9     NA   
##  5 region           "Midwest"   pct     21.6    21.2    21.4    21.3     NA   
##  6 region           "Northeast" pct     16.8    16.8    16.8    16.8     NA   
##  7 region           "South"     pct     40.7    41.1    40.7    40.8     NA   
##  8 region           "Unknown"   pct      0.27    0.48    0.4     0.38    NA   
##  9 region           "West"      pct     20.6    20.3    20.7    20.7     NA   
## 10 plan_type        "PPO"       pct     37.0    36.2    36.9    36.9     NA   
## 11 plan_type        "HMO"       pct     16.2    15.9    15.9    15.9     NA   
## 12 plan_type        "POS"       pct     13.2    13.9    13.8    13.6     NA   
## 13 plan_type        "EPO"       pct     10.8     9.77   10.0    10.1     NA   
## 14 plan_type        "CDHP"      pct     22.8    24.2    23.4    23.5     NA   
## 15 index_qtr        "2024Q1"    pct     14.7    19.2    16.9    17.0     NA   
## 16 index_qtr        "2024Q2"    pct     13.6    18.5    16.2    16.1     NA   
## 17 index_qtr        "2024Q3"    pct     16.8    17.1    17.0    17.0     NA   
## 18 index_qtr        "2024Q4"    pct     17.1    16.3    16.6    16.7     NA   
## 19 index_qtr        "2025Q1"    pct     18.7    13.7    16.3    16.3     NA   
## 20 index_qtr        "2025Q2"    pct     19      15.2    17.0    17.0     NA   
## 21 obesity_class    "Class 1"   pct     21.3    23.8    22.6    22.6     NA   
## 22 obesity_class    "Class 2"   pct     23.0    21.4    22.2    22.1     NA   
## 23 obesity_class    "Class 3"   pct     34.8    31.4    32.9    33.0     NA   
## 24 obesity_class    "Unknown"   pct     21.0    23.5    22.2    22.3     NA   
## 25 hypertension     ""          pct     40.7    41.1    41.2    41.0     NA   
## 26 dyslipidemia     ""          pct     34.4    37.6    36.2    36.1     NA   
## 27 sleep_apnea      ""          pct     36      32.1    34.1    34.2     NA   
## 28 prediabetes      ""          pct     23.9    22.9    23.4    23.4     NA   
## 29 masld            ""          pct     12.9    14.5    13.8    13.7     NA   
## 30 osteoarthritis   ""          pct     17.8    16.6    17.3    17.5     NA   
## 31 depression       ""          pct     21.2    21.1    21.1    21.1     NA   
## 32 anxiety          ""          pct     23.6    23.1    23.6    23.5     NA   
## 33 gerd             ""          pct     17.6    16.6    17.2    17.2     NA   
## 34 ascvd            ""          pct      3.28    6.41    4.79    4.87    NA   
## 35 heart_failure    ""          pct      1.92    3.43    2.8     2.68    NA   
## 36 ckd              ""          pct      2.11    2.83    2.56    2.48    NA   
## 37 pcos             ""          pct      4.3     4.1     4.32    4.23    NA   
## 38 hypothyroid      ""          pct      9.93   11.1    10.5    10.6     NA   
## 39 gallbladder      ""          pct      1.72    1.53    1.66    1.67    NA   
## 40 pancreatitis     ""          pct      1.29    1.19    1.2     1.21    NA   
## 41 prior_aom        ""          pct      0       0       0       0       NA   
## 42 metformin        ""          pct      4.5     4.62    4.65    4.66    NA   
## 43 antihypertensive ""          pct     30.5    30.8    30.8    30.6     NA   
## 44 statin           ""          pct     25.0    27.9    26.6    26.4     NA   
## 45 antidepressant   ""          pct     21.7    21.5    21.6    21.7     NA   
## 46 n_generics       ""          mean     1.66    1.68    1.68    1.67     1.17
## 47 bariatric_hx     ""          pct      1.99    2.09    2       2.06    NA   
## 48 endo_visit       ""          pct     39.2    41.4    40.3    40.3     NA   
## 49 base_any_ip      ""          pct      6.84    8.09    7.33    7.47    NA   
## 50 base_any_ed      ""          pct     16.3    20.7    18.9    18.7     NA   
## 51 base_op_visits   ""          mean     5.47    6.37    6       5.95     3.69
## 52 log_base_cost    ""          mean     7.16    7.38    7.28    7.28     1.26
## 53 base_med_cost    ""          mean  5153.   4857.   5976.   4371.   26238.  
## 54 base_rx_cost     ""          mean    92.2    95.4    94.0    93.9     87.0 
## 55 base_total_cost  ""          mean  5245.   4952.   6070.   4464.   26241.  
##     sema_sd smd_unweighted smd_weighted
##       <dbl>          <dbl>        <dbl>
##  1    NA             NA           NA   
##  2    10.4           -0.13         0   
##  3    NA             NA           NA   
##  4    NA             -0.06        -0.01
##  5    NA              0.01         0   
##  6    NA              0            0   
##  7    NA             -0.01         0   
##  8    NA             -0.03         0   
##  9    NA              0.01         0   
## 10    NA              0.02         0   
## 11    NA              0.01         0   
## 12    NA             -0.02         0   
## 13    NA              0.03         0   
## 14    NA             -0.03         0   
## 15    NA             -0.12         0   
## 16    NA             -0.13         0   
## 17    NA             -0.01         0   
## 18    NA              0.02         0   
## 19    NA              0.14         0   
## 20    NA              0.1          0   
## 21    NA             -0.06         0   
## 22    NA              0.04         0   
## 23    NA              0.07         0   
## 24    NA             -0.06         0   
## 25    NA             -0.01         0   
## 26    NA             -0.07         0   
## 27    NA              0.08         0   
## 28    NA              0.02         0   
## 29    NA             -0.05         0   
## 30    NA              0.03         0   
## 31    NA              0            0   
## 32    NA              0.01         0   
## 33    NA              0.03         0   
## 34    NA             -0.15         0   
## 35    NA             -0.09         0.01
## 36    NA             -0.05         0.01
## 37    NA              0.01         0   
## 38    NA             -0.04         0   
## 39    NA              0.02         0   
## 40    NA              0.01         0   
## 41    NA              0            0   
## 42    NA             -0.01         0   
## 43    NA             -0.01         0.01
## 44    NA             -0.07         0   
## 45    NA              0            0   
## 46     1.14          -0.01         0   
## 47    NA             -0.01         0   
## 48    NA             -0.04         0   
## 49    NA             -0.05        -0.01
## 50    NA             -0.11         0   
## 51     4.27          -0.23         0.01
## 52     1.24          -0.17         0   
## 53 18444.            NA           NA   
## 54    84.9           NA           NA   
## 55 18448.            NA           NA
```

**What.** Plot the propensity score overlap (Figure 2) and a Love plot of balance (Figure 3).

**Why.** Overlap checks positivity (each type of patient could have received either drug); the Love plot shows balance at a glance.


``` r
p_overlap <- ggplot(analytic, aes(x = ps, fill = drug)) +
  geom_density(alpha = 0.45, colour = NA) +
  scale_fill_manual(values = col_drug, name = NULL) +
  labs(x = "Propensity score (probability of starting tirzepatide)", y = "Density",
       title = "Figure 2. Propensity score overlap") +
  theme(legend.position = "bottom")
ggsave(file.path(dir_figures, "fig2_ps_overlap.png"), p_overlap, width = 7, height = 4.5, dpi = 200, bg = "white")

p_love <- cobalt::love.plot(w_ate, binary = "std", abs = TRUE, thresholds = c(m = 0.1),
                            var.order = "unadjusted", line = FALSE, stars = "none",
                            colors = c("#B5B5B5", "#1F6FB4"), shapes = c("circle", "triangle"),
                            sample.names = c("Unweighted", "IPTW")) +
  labs(title = "Figure 3. Covariate balance before and after weighting")
ggsave(file.path(dir_figures, "fig3_love_plot.png"), p_love, width = 7.5, height = 9, dpi = 200, bg = "white")

summary(analytic$w)
```

```
##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
##  0.5720  0.8394  0.9516  1.0004  1.1079  6.5256
```

# Step 10. Outcome models

**What.** Helper functions: `robust_ci()` (robust sandwich standard errors with `sandwich::vcovHC(type = "HC0")`), `wmean_by()` (weighted means by group) and `binary_effect()` (risk difference from a weighted linear model and risk ratio from a weighted log-link model).

**Why.** Weighted analyses need robust variance; each binary outcome is analysed in the same way.


``` r
analytic <- readRDS(file.path(dir_derived, "analytic_weighted.rds"))
ps_spec  <- readRDS(file.path(dir_derived, "ps_spec.rds"))

robust_ci <- function(fit, term = "treat", exp = FALSE) {
  est <- coef(fit)[[term]]; se <- sqrt(sandwich::vcovHC(fit, type = "HC0")[term, term])
  ci  <- est + c(-1, 1) * qnorm(0.975) * se
  p   <- 2 * pnorm(-abs(est / se))
  if (exp) c(est = exp(est), lo = exp(ci[1]), hi = exp(ci[2]), p = p) else c(est = est, lo = ci[1], hi = ci[2], p = p)
}
wmean_by <- function(y, d = analytic) {
  c(tirz = weighted.mean(y[d$treat == 1], d$w[d$treat == 1]),
    sema = weighted.mean(y[d$treat == 0], d$w[d$treat == 0]))
}
# Binary outcome: weighted proportions, risk difference (linear probability) and risk ratio (log link)
binary_effect <- function(y_name, d = analytic, label = y_name) {
  d$y <- as.numeric(d[[y_name]])
  rd <- robust_ci(lm(y ~ treat, data = d, weights = w))
  rr <- robust_ci(glm(y ~ treat, data = d, weights = w, family = quasipoisson(link = "log")), exp = TRUE)
  m  <- wmean_by(d$y, d)
  tibble(outcome = label, tirz = m[["tirz"]] * 100, sema = m[["sema"]] * 100,
         diff = rd[["est"]] * 100, diff_lo = rd[["lo"]] * 100, diff_hi = rd[["hi"]] * 100,
         ratio = rr[["est"]], ratio_lo = rr[["lo"]], ratio_hi = rr[["hi"]], p = rr[["p"]], measure = "RD (pct points) / RR")
}
```

**What**

- Primary outcome: `binary_effect("persistent")`.
- Time to discontinuation: weighted Kaplan-Meier (`survfit(..., weights = w)`) and weighted Cox model (`coxph(..., robust = TRUE)`); proportional hazards test (`cox.zph()`).
- Restricted mean days on treatment (`rmst()`); Kaplan-Meier figure (Figure 4).

**Why.** Aim 1 asks for both persistence at 12 months and time to discontinuation. RMST is easy to interpret ("days on treatment") and stays valid if hazards are not proportional.


``` r
# Primary outcome: persistence at 12 months
primary <- binary_effect("persistent", label = "Persistent at 12 months (60-day gap)")
print(primary)
```

```
## # A tibble: 1 × 11
##   outcome       tirz  sema  diff diff_lo diff_hi ratio ratio_lo ratio_hi       p
##   <chr>        <dbl> <dbl> <dbl>   <dbl>   <dbl> <dbl>    <dbl>    <dbl>   <dbl>
## 1 Persistent …  58.0  50.8  7.11    4.34    9.88  1.14     1.08     1.20 5.40e-7
## # ℹ 1 more variable: measure <chr>
```

``` r
# Time to discontinuation: weighted Kaplan-Meier and weighted Cox (robust variance)
km  <- survfit(Surv(time_to_disc, discontinued) ~ drug, data = analytic, weights = w)
cox <- coxph(Surv(time_to_disc, discontinued) ~ treat, data = analytic, weights = w, robust = TRUE)
hr  <- summary(cox)$conf.int
ph_test <- cox.zph(cox)
print(summary(cox)); print(ph_test)
```

```
## Call:
## coxph(formula = Surv(time_to_disc, discontinued) ~ treat, data = analytic, 
##     weights = w, robust = TRUE)
## 
##   n= 5240, number of events= 2389 
## 
##           coef exp(coef) se(coef) robust se      z Pr(>|z|)    
## treat -0.20793   0.81226  0.04109   0.04239 -4.905 9.33e-07 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
##       exp(coef) exp(-coef) lower .95 upper .95
## treat    0.8123      1.231    0.7475    0.8826
## 
## Concordance= 0.525  (se = 0.005 )
## Likelihood ratio test= 25.74  on 1 df,   p=4e-07
## Wald test            = 24.06  on 1 df,   p=9e-07
## Score (logrank) test = 25.7  on 1 df,   p=4e-07,   Robust = 24.17  p=9e-07
## 
##   (Note: the likelihood ratio and score tests assume independence of
##      observations within a cluster, the Wald and robust score tests do not).
```

```
##        chisq df    p
## treat  0.673  1 0.41
## GLOBAL 0.673  1 0.41
```

``` r
# Restricted mean time on treatment over 365 days (area under each weighted KM curve)
rmst <- function(fit) {
  s <- summary(fit, times = c(0, fit$time), extend = TRUE)
  tapply(seq_along(s$time), s$strata, function(i) {
    t <- c(s$time[i], 365); S <- s$surv[i]
    keep <- t[-length(t)] < 365
    sum(diff(pmin(t, 365))[keep] * S[keep])
  })
}
rmst_km <- rmst(km); print(rmst_km)
```

```
## drug=Semaglutide 2.4 mg        drug=Tirzepatide 
##                249.7031                266.2471
```

``` r
p_km <- survminer::ggsurvplot(km, data = analytic, conf.int = TRUE, censor = FALSE,
                              palette = unname(col_drug[c("Semaglutide 2.4 mg", "Tirzepatide")]),
                              legend.labs = c("Semaglutide 2.4 mg", "Tirzepatide"), legend.title = "",
                              xlab = "Days since index", ylab = "Proportion still on index drug",
                              break.time.by = 60, xlim = c(0, 365), ylim = c(0, 1),
                              title = "Figure 4. Time to discontinuation (IPTW-weighted Kaplan-Meier)",
                              ggtheme = theme_minimal(base_size = 11))
ggsave(file.path(dir_figures, "fig4_km_discontinuation.png"), p_km$plot, width = 7.5, height = 5, dpi = 200, bg = "white")
```

**What.** PDC mean difference (weighted linear model), PDC >= 80% and switching (`binary_effect()`), combined into Table 2.

**Why.** Aim 2 (adherence and switching).


``` r
pdc_fit <- lm(pdc ~ treat, data = analytic, weights = w)
pdc_eff <- robust_ci(pdc_fit)
pdc_m   <- wmean_by(analytic$pdc)
table2 <- bind_rows(
  primary,
  tibble(outcome = "Time to discontinuation (hazard ratio)", ratio = hr[1, "exp(coef)"],
         ratio_lo = hr[1, "lower .95"], ratio_hi = hr[1, "upper .95"],
         p = summary(cox)$coefficients[1, "Pr(>|z|)"], measure = "HR"),
  tibble(outcome = "Restricted mean days on treatment (0-365)", tirz = rmst_km[[2]], sema = rmst_km[[1]],
         diff = rmst_km[[2]] - rmst_km[[1]], measure = "Mean difference (days); CI from bootstrap"),
  tibble(outcome = "PDC, mean (%)", tirz = pdc_m[["tirz"]] * 100, sema = pdc_m[["sema"]] * 100,
         diff = pdc_eff[["est"]] * 100, diff_lo = pdc_eff[["lo"]] * 100, diff_hi = pdc_eff[["hi"]] * 100,
         p = pdc_eff[["p"]], measure = "Mean difference (pct points)"),
  binary_effect("pdc80", label = "Adherent (PDC >= 80%)"),
  binary_effect("switched", label = "Switched to the other drug")
)
```

**What.** Any inpatient admission and any ED visit (`binary_effect()`); outpatient and obesity-related visit counts with weighted negative binomial models (`MASS::glm.nb()`), with the Poisson dispersion as a check.

**Why.** Aim 3. Visit counts are overdispersed (variance > mean), which the negative binomial model allows.


``` r
table3_bin <- bind_rows(
  binary_effect("any_ip", label = "Any inpatient admission"),
  binary_effect("any_ed", label = "Any emergency department visit")
)
count_effect <- function(y_name, label) {
  f  <- reformulate("treat", response = y_name)
  nb <- MASS::glm.nb(f, data = analytic, weights = w)
  po <- glm(f, data = analytic, weights = w, family = poisson)
  dispersion <- sum(residuals(po, type = "pearson")^2) / po$df.residual
  rr <- robust_ci(nb, exp = TRUE); m <- wmean_by(analytic[[y_name]])
  list(row = tibble(outcome = label, tirz = m[["tirz"]], sema = m[["sema"]], diff = m[["tirz"]] - m[["sema"]],
                    ratio = rr[["est"]], ratio_lo = rr[["lo"]], ratio_hi = rr[["hi"]], p = rr[["p"]],
                    measure = "Mean difference / rate ratio (negative binomial)"),
       dispersion = dispersion, theta = nb$theta)
}
op  <- count_effect("n_outpatient", "Outpatient visits, mean")
opo <- count_effect("n_outpatient_obesity", "Obesity-related outpatient visits, mean")
```

**What**

- Total and pharmacy costs: weighted gamma GLM with log link (`family = Gamma(link = "log")`) gives the cost ratio.
- Medical costs (some are $0): two-part model, part 1 logistic for any cost and part 2 gamma for positive costs (`twopart_mean()`).
- Weighted mean costs by group (`cost_means`).

**Why.** Aim 4. Costs are skewed and cannot be negative; the gamma-log GLM models the mean directly without retransformation problems, and the two-part model handles zeros.


``` r
# Gamma GLM (log link) for strictly positive costs; two-part model for medical costs (zeros allowed)
cost_ratio <- function(y_name) {
  robust_ci(glm(reformulate("treat", response = y_name), data = analytic, weights = w,
                family = Gamma(link = "log")), exp = TRUE)
}
cr_total <- cost_ratio("cost_total"); cr_rx <- cost_ratio("cost_pharmacy")
analytic$any_med_cost <- analytic$cost_medical > 0
part1 <- glm(any_med_cost ~ treat, data = analytic, weights = w, family = quasibinomial)
part2 <- glm(cost_medical ~ treat, data = subset(analytic, cost_medical > 0), weights = w, family = Gamma(link = "log"))
twopart_mean <- function(t) {
  nd <- data.frame(treat = t)
  predict(part1, nd, type = "response") * predict(part2, nd, type = "response")
}
cr_med <- c(est = unname(twopart_mean(1) / twopart_mean(0)))
cost_means <- sapply(c("cost_medical", "cost_pharmacy", "cost_total", "cost_study_drug"), function(v) wmean_by(analytic[[v]]))
print(round(cost_means))
```

```
##      cost_medical cost_pharmacy cost_total cost_study_drug
## tirz         4420          9403      13822            9308
## sema         4327         11197      15524           11102
```

**What.** Bootstrap 500 times (`boot_once()`): resample patients, re-estimate the propensity score and weights, and recompute the cost differences and RMST difference; take the 2.5th and 97.5th percentiles as the 95% CI. Assemble and save Tables 2 and 3.

**Why.** Confidence intervals for differences in mean costs should reflect skewness and the uncertainty from estimating the weights; the bootstrap does both.


``` r
# Bootstrap (500 replicates): re-estimate the propensity score and weights in each resample,
# then recompute weighted mean cost differences and the restricted mean time on treatment
boot_once <- function(i) {
  d <- analytic[sample.int(nrow(analytic), replace = TRUE), ]
  ps <- fitted(glm(ps_spec$ps_formula, data = d, family = binomial))
  pt <- mean(d$treat)
  d$w <- ifelse(d$treat == 1, pt / ps, (1 - pt) / (1 - ps))
  m <- sapply(c("cost_medical", "cost_pharmacy", "cost_total"), function(v) {
    x <- wmean_by(d[[v]], d); x[["tirz"]] - x[["sema"]] })
  r <- rmst(survfit(Surv(time_to_disc, discontinued) ~ drug, data = d, weights = w))
  c(m, rmst = r[[2]] - r[[1]])
}
set.seed(20261007)
boot <- do.call(rbind, lapply(1:500, boot_once))
boot_ci <- apply(boot, 2, quantile, probs = c(0.025, 0.975))
print(round(boot_ci, 1))
```

```
##       cost_medical cost_pharmacy cost_total rmst
## 2.5%       -1323.2       -2055.5    -3033.2  9.2
## 97.5%       1395.3       -1530.4     -370.9 24.0
```

``` r
saveRDS(boot, file.path(dir_derived, "bootstrap_replicates.rds"))

table2$diff_lo[table2$outcome == "Restricted mean days on treatment (0-365)"] <- boot_ci[1, "rmst"]
table2$diff_hi[table2$outcome == "Restricted mean days on treatment (0-365)"] <- boot_ci[2, "rmst"]

cost_row <- function(v, label, ratio_ci) {
  has_ci <- length(ratio_ci) > 1
  tibble(outcome = label, tirz = cost_means["tirz", v], sema = cost_means["sema", v],
         diff = cost_means["tirz", v] - cost_means["sema", v],
         diff_lo = boot_ci[1, v], diff_hi = boot_ci[2, v],
         ratio = ratio_ci[["est"]], ratio_lo = if (has_ci) ratio_ci[["lo"]] else NA,
         ratio_hi = if (has_ci) ratio_ci[["hi"]] else NA, p = if (has_ci) ratio_ci[["p"]] else NA,
         measure = "Mean difference $ (bootstrap CI) / cost ratio")
}
table3 <- bind_rows(
  table3_bin, op$row, opo$row,
  cost_row("cost_medical", "Medical cost, mean $ (two-part model)", cr_med),
  cost_row("cost_pharmacy", "Pharmacy cost, mean $ (gamma GLM)", cr_rx),
  cost_row("cost_total", "Total cost, mean $ (gamma GLM)", cr_total),
  tibble(outcome = "  of which study-drug pharmacy cost, mean $", tirz = cost_means["tirz", "cost_study_drug"],
         sema = cost_means["sema", "cost_study_drug"],
         diff = cost_means["tirz", "cost_study_drug"] - cost_means["sema", "cost_study_drug"], measure = "Descriptive")
)
readr::write_csv(table2, file.path(dir_tables, "table2_persistence_adherence.csv"))
readr::write_csv(table3, file.path(dir_tables, "table3_hcru_costs.csv"))
print(table2, width = 200); print(table3, width = 200)
```

```
## # A tibble: 6 × 11
##   outcome                                     tirz   sema  diff diff_lo diff_hi
##   <chr>                                      <dbl>  <dbl> <dbl>   <dbl>   <dbl>
## 1 Persistent at 12 months (60-day gap)       58.0   50.8   7.11    4.34    9.88
## 2 Time to discontinuation (hazard ratio)     NA     NA    NA      NA      NA   
## 3 Restricted mean days on treatment (0-365) 266.   250.   16.5     9.16   24.0 
## 4 PDC, mean (%)                              64.1   60.3   3.77    2.18    5.36
## 5 Adherent (PDC >= 80%)                      45.9   40.5   5.36    2.60    8.13
## 6 Switched to the other drug                  2.18   8.90 -6.72   -7.97   -5.47
##    ratio ratio_lo ratio_hi         p measure                                  
##    <dbl>    <dbl>    <dbl>     <dbl> <chr>                                    
## 1  1.14     1.08     1.20   5.40e- 7 RD (pct points) / RR                     
## 2  0.812    0.748    0.883  9.33e- 7 HR                                       
## 3 NA       NA       NA     NA        Mean difference (days); CI from bootstrap
## 4 NA       NA       NA      3.28e- 6 Mean difference (pct points)             
## 5  1.13     1.06     1.21   1.45e- 4 RD (pct points) / RR                     
## 6  0.245    0.183    0.328  3.25e-21 RD (pct points) / RR
```

```
## # A tibble: 8 × 11
##   outcome                                           tirz     sema      diff
##   <chr>                                            <dbl>    <dbl>     <dbl>
## 1 "Any inpatient admission"                         4.17     4.71    -0.539
## 2 "Any emergency department visit"                 23.2     24.6     -1.38 
## 3 "Outpatient visits, mean"                         5.62     5.82    -0.195
## 4 "Obesity-related outpatient visits, mean"         3.38     3.52    -0.144
## 5 "Medical cost, mean $ (two-part model)"        4420.    4327.      92.4  
## 6 "Pharmacy cost, mean $ (gamma GLM)"            9403.   11197.   -1794.   
## 7 "Total cost, mean $ (gamma GLM)"              13822.   15524.   -1702.   
## 8 "  of which study-drug pharmacy cost, mean $"  9308.   11102.   -1794.   
##    diff_lo   diff_hi  ratio ratio_lo ratio_hi         p
##      <dbl>     <dbl>  <dbl>    <dbl>    <dbl>     <dbl>
## 1    -1.70     0.620  0.885    0.680    1.15   3.65e- 1
## 2    -3.75     1.00   0.944    0.854    1.04   2.58e- 1
## 3    NA       NA      0.967    0.923    1.01   1.44e- 1
## 4    NA       NA      0.959    0.913    1.01   9.44e- 2
## 5 -1323.    1395.     1.02    NA       NA     NA       
## 6 -2055.   -1530.     0.840    0.819    0.861  1.32e-43
## 7 -3033.    -371.     0.890    0.813    0.975  1.25e- 2
## 8    NA       NA     NA       NA       NA     NA       
##   measure                                         
##   <chr>                                           
## 1 RD (pct points) / RR                            
## 2 RD (pct points) / RR                            
## 3 Mean difference / rate ratio (negative binomial)
## 4 Mean difference / rate ratio (negative binomial)
## 5 Mean difference $ (bootstrap CI) / cost ratio   
## 6 Mean difference $ (bootstrap CI) / cost ratio   
## 7 Mean difference $ (bootstrap CI) / cost ratio   
## 8 Descriptive
```

**What**

- Proportional hazards global test.
- Modified Park test for the cost variance function (slope near 2 supports gamma).
- Poisson dispersion for visit counts.
- Share of $0 medical costs; Schoenfeld residual plot.

**Why.** Workflow step 9: confirm each model's assumptions before interpreting it, and record any departure.


``` r
# Modified Park test on a covariate-adjusted weighted gamma model of total cost:
# slope ~ 2 supports the gamma variance function (0 = Gaussian, 1 = Poisson, 3 = inverse Gaussian)
adj_cost <- glm(update(ps_spec$ps_formula, cost_total ~ treat + .), data = analytic, weights = w,
                family = Gamma(link = "log"))
mu <- fitted(adj_cost)
park <- glm(I((analytic$cost_total - mu)^2) ~ log(mu), family = quasipoisson(link = "log"), weights = analytic$w)
park_slope <- coef(park)[2]

# SAP contingency if the Park slope is far from 2: re-estimate the total-cost ratio under an
# inverse Gaussian variance (slope ~ 3) and a log-normal model with Duan smearing by group
gamma_total <- glm(cost_total ~ treat, data = analytic, weights = w, family = Gamma(link = "log"))
ig_ratio <- robust_ci(glm(cost_total ~ treat, data = analytic, weights = w,
                          family = inverse.gaussian(link = "log"), start = coef(gamma_total)), exp = TRUE)
ln_fit   <- lm(log(cost_total) ~ treat, data = analytic, weights = w)
smear    <- sapply(0:1, function(t) {
  i <- analytic$treat == t; weighted.mean(exp(residuals(ln_fit)[i]), analytic$w[i]) })
ln_ratio <- exp(coef(ln_fit)[["treat"]]) * smear[2] / smear[1]

checks <- c(
  sprintf("Proportional hazards (cox.zph) global p = %.3f", ph_test$table["GLOBAL", "p"]),
  sprintf("Modified Park test slope (total cost) = %.2f (gamma ~ 2)", park_slope),
  sprintf("Total cost ratio: gamma %.3f (%.3f-%.3f); inverse Gaussian %.3f (%.3f-%.3f); log-normal with smearing %.3f",
          cr_total[["est"]], cr_total[["lo"]], cr_total[["hi"]],
          ig_ratio[["est"]], ig_ratio[["lo"]], ig_ratio[["hi"]], ln_ratio),
  sprintf("Poisson dispersion, outpatient visits = %.2f (>1 = overdispersion; negative binomial theta = %.2f)",
          op$dispersion, op$theta),
  sprintf("Poisson dispersion, obesity-related visits = %.2f", opo$dispersion),
  sprintf("Share of patients with $0 medical cost = %.1f%%", 100 * mean(analytic$cost_medical == 0))
)
writeLines(checks, file.path(dir_tables, "model_checks.txt")); cat(checks, sep = "\n")
```

```
## Proportional hazards (cox.zph) global p = 0.412
## Modified Park test slope (total cost) = 3.58 (gamma ~ 2)
## Total cost ratio: gamma 0.890 (0.813-0.975); inverse Gaussian 0.890 (0.813-0.975); log-normal with smearing 0.890
## Poisson dispersion, outpatient visits = 3.02 (>1 = overdispersion; negative binomial theta = 3.06)
## Poisson dispersion, obesity-related visits = 2.54
## Share of patients with $0 medical cost = 2.3%
```

``` r
png(file.path(dir_figures, "figS1_schoenfeld.png"), width = 1400, height = 900, res = 200)
plot(ph_test, resid = FALSE, main = "Scaled Schoenfeld residuals: tirzepatide vs semaglutide"); abline(h = coef(cox), lty = 2, col = "red")
dev.off()
```

```
## quartz_off_screen 
##                 2
```

**What.** Plot weighted cost distributions on a log scale (Figure 5).

**Why.** It shows the skewness that justified the gamma and two-part models.


``` r
cost_long <- analytic |>
  select(drug, w, Medical = cost_medical, Pharmacy = cost_pharmacy, Total = cost_total) |>
  tidyr::pivot_longer(Medical:Total, names_to = "component", values_to = "cost")
p_cost <- ggplot(cost_long, aes(x = cost + 1, fill = drug, weight = w)) +
  geom_density(alpha = 0.45, colour = NA) +
  scale_x_log10(labels = scales::dollar) +
  facet_wrap(~ component, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = col_drug, name = NULL) +
  labs(x = "12-month allowed cost + $1 (log scale)", y = "Weighted density",
       title = "Figure 5. Distribution of 12-month costs by drug (IPTW)") +
  theme(legend.position = "bottom")
ggsave(file.path(dir_figures, "fig5_cost_distributions.png"), p_cost, width = 7, height = 7, dpi = 200, bg = "white")
```

# Step 11. Subgroup, sensitivity and bias analyses

**What.** Helpers: `persist_effect()` (weighted RD and RR for any data, outcome and weight column) and `reweight()` (re-estimates weights when the population changes).

**Why.** Every sensitivity analysis is computed the same way, so only the planned change differs from the primary analysis.


``` r
analytic <- readRDS(file.path(dir_derived, "analytic_weighted.rds"))
ps_spec  <- readRDS(file.path(dir_derived, "ps_spec.rds"))

robust_ci <- function(fit, term = "treat", exp = FALSE) {
  est <- coef(fit)[[term]]; se <- sqrt(sandwich::vcovHC(fit, type = "HC0")[term, term])
  ci  <- est + c(-1, 1) * qnorm(0.975) * se
  if (exp) c(est = exp(est), lo = exp(ci[1]), hi = exp(ci[2])) else c(est = est, lo = ci[1], hi = ci[2])
}
# Weighted persistence comparison in data `d` with weights column `w`
persist_effect <- function(d, label, y = "persistent", wcol = "w") {
  d$y <- as.numeric(d[[y]]); d$wt <- d[[wcol]]
  rd_ci <- robust_ci(lm(y ~ treat, data = d, weights = wt))
  rr_ci <- robust_ci(glm(y ~ treat, data = d, weights = wt, family = quasipoisson(link = "log")), exp = TRUE)
  tibble(analysis = label, n = nrow(d),
         tirz = 100 * weighted.mean(d$y[d$treat == 1], d$wt[d$treat == 1]),
         sema = 100 * weighted.mean(d$y[d$treat == 0], d$wt[d$treat == 0]),
         rd = 100 * rd_ci[["est"]], rd_lo = 100 * rd_ci[["lo"]], rd_hi = 100 * rd_ci[["hi"]],
         rr = rr_ci[["est"]], rr_lo = rr_ci[["lo"]], rr_hi = rr_ci[["hi"]])
}
# Re-estimate stabilized ATE weights within a subset (the population changes)
reweight <- function(d, drop = character()) {
  f <- reformulate(setdiff(ps_spec$covs, drop), response = "treat")
  d$w <- WeightIt::weightit(f, data = droplevels(d), method = "glm", estimand = "ATE", stabilize = TRUE)$weights
  d
}
```

**What.** For each prespecified subgroup (obesity class, sex, age group, CDHP), estimate RD and RR within each level and test the treatment-by-subgroup interaction with a robust multi-degree-of-freedom Wald test (`t(b) %*% solve(V) %*% b`).

**Why.** Aim 5. Interaction tests guard against over-reading chance differences between subgroups.


``` r
subgroup_vars <- c(obesity_class = "Obesity class", sex = "Sex", age_group = "Age group", cdhp = "Plan type")
subgroups <- purrr::imap_dfr(subgroup_vars, function(lab, v) {
  # interaction test: weighted log-link model with treat x subgroup, robust Wald test (multi-df)
  fit <- glm(reformulate(c("treat", v, paste0("treat:", v)), response = "as.numeric(persistent)"),
             data = analytic, weights = w, family = quasipoisson(link = "log"))
  ix  <- grep("^treat:", names(coef(fit)))
  V   <- sandwich::vcovHC(fit, type = "HC0")[ix, ix, drop = FALSE]
  b   <- coef(fit)[ix]
  p_int <- pchisq(as.numeric(t(b) %*% solve(V) %*% b), df = length(ix), lower.tail = FALSE)
  purrr::map_dfr(levels(analytic[[v]]), function(l) {
    persist_effect(analytic[analytic[[v]] == l, ], label = l)
  }) |> mutate(subgroup = lab, p_interaction = p_int, .before = 1)
})
readr::write_csv(subgroups, file.path(dir_tables, "table4_subgroups.csv"))
print(subgroups, width = 200)
```

```
## # A tibble: 10 × 12
##    subgroup      p_interaction analysis     n  tirz  sema    rd  rd_lo rd_hi
##    <chr>                 <dbl> <chr>    <int> <dbl> <dbl> <dbl>  <dbl> <dbl>
##  1 Obesity class         0.393 Class 1   1182  56.0  49.3  6.70  0.859 12.5 
##  2 Obesity class         0.393 Class 2   1160  53.0  50.0  3.00 -2.92   8.92
##  3 Obesity class         0.393 Class 3   1730  64.6  53.9 10.7   5.95  15.4 
##  4 Obesity class         0.393 Unknown   1168  55.0  48.7  6.33  0.445 12.2 
##  5 Sex                   0.623 Female    3519  56.8  50.3  6.52  3.12   9.91
##  6 Sex                   0.623 Male      1721  60.4  52.0  8.35  3.55  13.1 
##  7 Age group             0.286 18-44     2519  53.1  45.0  8.09  4.11  12.1 
##  8 Age group             0.286 45-64     2721  62.5  56.1  6.42  2.61  10.2 
##  9 Plan type             0.497 Non-CDHP  4010  59.4  51.6  7.78  4.62  10.9 
## 10 Plan type             0.497 CDHP      1230  53.4  48.5  4.91 -0.832 10.7 
##       rr rr_lo rr_hi
##    <dbl> <dbl> <dbl>
##  1  1.14 1.02   1.27
##  2  1.06 0.945  1.19
##  3  1.20 1.10   1.30
##  4  1.13 1.01   1.27
##  5  1.13 1.06   1.20
##  6  1.16 1.07   1.26
##  7  1.18 1.09   1.28
##  8  1.11 1.05   1.19
##  9  1.15 1.09   1.22
## 10  1.10 0.984  1.23
```

**What.** Sensitivity analyses from the SAP:

- S1-S3: alternative persistence definitions;
- S4: 1:1 PS matching (`MatchIt::matchit(caliper = 0.2)`);
- S5: trimmed weights;
- S6: doubly robust g-computation (`marginaleffects::avg_comparisons()`);
- S7: excluding metformin users;
- S8: recorded obesity class only;
- S11: negative control outcome.

**Why.** Aim 6. If conclusions stay the same across definitions and methods, they are less likely to be artefacts of a single analytic choice.


``` r
primary <- persist_effect(analytic, "Primary: IPTW, 60-day gap")

# S4: 1:1 nearest-neighbour matching on the logit PS, caliper 0.2 SD (ATT)
m_out <- MatchIt::matchit(ps_spec$ps_formula, data = analytic, method = "nearest",
                          distance = "glm", link = "linear.logit", caliper = 0.2, estimand = "ATT")
matched <- MatchIt::match.data(m_out)
bal_m <- cobalt::bal.tab(m_out, binary = "std")$Balance
max_smd_matched <- max(abs(bal_m[rownames(bal_m) != "distance", "Diff.Adj"]), na.rm = TRUE)  # covariates only

# S5: weights truncated at the 1st and 99th percentiles
trimmed <- analytic |> mutate(w = pmin(pmax(w, quantile(w, 0.01)), quantile(w, 0.99)))

# S6: doubly robust g-computation (weighted outcome model with all covariates)
dr_fit <- glm(update(ps_spec$ps_formula, as.numeric(persistent) ~ treat + .), data = analytic,
              weights = w, family = quasibinomial)
dr_rd <- marginaleffects::avg_comparisons(dr_fit, variables = "treat", wts = "w", vcov = "HC0")
dr_rr <- marginaleffects::avg_comparisons(dr_fit, variables = "treat", wts = "w", vcov = "HC0",
                                          comparison = "lnratioavg", transform = exp)

sensitivity <- bind_rows(
  primary,
  persist_effect(analytic, "S1: 30-day gap", y = "persistent_g30"),
  persist_effect(analytic, "S2: 90-day gap", y = "persistent_g90"),
  persist_effect(analytic, "S3: Either drug (switching allowed)", y = "persistent_class"),
  persist_effect(matched, "S4: 1:1 PS matching (ATT)", wcol = "weights"),
  persist_effect(trimmed, "S5: Weights trimmed at 1st/99th percentile"),
  tibble(analysis = "S6: Doubly robust (IPTW + outcome model)", n = nrow(analytic),
         rd = 100 * dr_rd$estimate, rd_lo = 100 * dr_rd$conf.low, rd_hi = 100 * dr_rd$conf.high,
         rr = dr_rr$estimate, rr_lo = dr_rr$conf.low, rr_hi = dr_rr$conf.high),
  persist_effect(reweight(filter(analytic, !metformin)), "S7: Excluding baseline metformin users"),
  persist_effect(reweight(filter(analytic, obesity_class != "Unknown")), "S8: Recorded obesity class only"),
  persist_effect(analytic, "S11: Negative control outcome - cancer screening", y = "neg_control")
)
print(sensitivity, width = 200)
```

```
## # A tibble: 10 × 10
##    analysis                                             n  tirz  sema     rd
##    <chr>                                            <int> <dbl> <dbl>  <dbl>
##  1 Primary: IPTW, 60-day gap                         5240 58.0  50.8   7.11 
##  2 S1: 30-day gap                                    5240 42.4  37.0   5.39 
##  3 S2: 90-day gap                                    5240 61.2  53.8   7.38 
##  4 S3: Either drug (switching allowed)               5240 58.9  55.0   3.92 
##  5 S4: 1:1 PS matching (ATT)                         4708 57.7  51.0   6.71 
##  6 S5: Weights trimmed at 1st/99th percentile        5240 57.8  50.8   6.98 
##  7 S6: Doubly robust (IPTW + outcome model)          5240 NA    NA     7.11 
##  8 S7: Excluding baseline metformin users            5001 57.9  51.4   6.49 
##  9 S8: Recorded obesity class only                   4072 58.8  51.6   7.16 
## 10 S11: Negative control outcome - cancer screening  5240  6.69  7.14 -0.447
##    rd_lo rd_hi    rr rr_lo rr_hi
##    <dbl> <dbl> <dbl> <dbl> <dbl>
##  1  4.34  9.88 1.14  1.08   1.20
##  2  2.66  8.12 1.15  1.07   1.23
##  3  4.63 10.1  1.14  1.08   1.19
##  4  1.16  6.68 1.07  1.02   1.12
##  5  3.87  9.55 1.13  1.07   1.19
##  6  4.22  9.74 1.14  1.08   1.20
##  7  4.40  9.82 1.14  1.08   1.20
##  8  3.65  9.34 1.13  1.07   1.19
##  9  4.02 10.3  1.14  1.08   1.21
## 10 -1.94  1.05 0.937 0.754  1.17
```

``` r
message("Matched pairs: ", sum(matched$treat == 1), "; largest covariate SMD after matching: ", round(max_smd_matched, 3))
```

**What.** S9: winsorize costs at the 99th percentile (`wins()`) and recompute weighted mean differences.

**Why.** It shows whether a few very expensive patients drive the cost results.


``` r
# S9: costs winsorized at the 99th percentile (all patients pooled)
wins <- function(x) pmin(x, quantile(x, 0.99))
cost_sens <- purrr::map_dfr(c("cost_medical", "cost_pharmacy", "cost_total"), function(v) {
  x <- analytic[[v]]; xw <- wins(x); t1 <- analytic$treat == 1
  tibble(outcome = v,
         diff_raw  = weighted.mean(x[t1], analytic$w[t1]) - weighted.mean(x[!t1], analytic$w[!t1]),
         diff_wins = weighted.mean(xw[t1], analytic$w[t1]) - weighted.mean(xw[!t1], analytic$w[!t1]),
         ratio_wins = weighted.mean(xw[t1], analytic$w[t1]) / weighted.mean(xw[!t1], analytic$w[!t1]))
})
readr::write_csv(cost_sens, file.path(dir_tables, "table5b_cost_sensitivity.csv"))
print(cost_sens)
```

```
## # A tibble: 3 × 4
##   outcome       diff_raw diff_wins ratio_wins
##   <chr>            <dbl>     <dbl>      <dbl>
## 1 cost_medical      92.4     -160.      0.948
## 2 cost_pharmacy  -1794.     -1759.      0.842
## 3 cost_total     -1702.     -1936.      0.865
```

**What.** S10: E-values for the primary risk ratio (`EValue::evalues.RR()`) and hazard ratio (`evalues.HR(rare = FALSE)`).

**Why.** The E-value is the minimum strength of association an unmeasured confounder would need with both drug choice and persistence to explain away the result.


``` r
# S10: E-values (minimum strength of unmeasured confounding, on the RR scale, needed to explain away
# the estimate and its confidence limit). Persistence is common (>15%), so the HR is converted.
cox <- coxph(Surv(time_to_disc, discontinued) ~ treat, data = analytic, weights = w, robust = TRUE)
hr  <- summary(cox)$conf.int
ev_rr <- EValue::evalues.RR(primary$rr, primary$rr_lo, primary$rr_hi)
ev_hr <- EValue::evalues.HR(hr[1, 1], hr[1, 3], hr[1, 4], rare = FALSE)
evalues <- tibble(
  estimate = c("RR persistent at 12 months", "HR discontinuation"),
  point = c(primary$rr, hr[1, 1]), lo = c(primary$rr_lo, hr[1, 3]), hi = c(primary$rr_hi, hr[1, 4]),
  evalue_point = c(ev_rr["E-values", "point"], ev_hr["E-values", "point"]),
  evalue_ci    = c(ev_rr["E-values", "lower"], ev_hr["E-values", "upper"]))
readr::write_csv(evalues, file.path(dir_tables, "evalues.csv"))
print(evalues)
```

```
## # A tibble: 2 × 6
##   estimate                   point    lo    hi evalue_point evalue_ci
##   <chr>                      <dbl> <dbl> <dbl>        <dbl>     <dbl>
## 1 RR persistent at 12 months 1.14  1.08  1.20          1.54      1.38
## 2 HR discontinuation         0.812 0.748 0.883         1.58      1.40
```

``` r
readr::write_csv(sensitivity, file.path(dir_tables, "table5_sensitivity.csv"))
```

**What.** Forest plots of the subgroup (Figure 6) and sensitivity (Figure 7) results.

**Why.** It summarises robustness visually for the paper.


``` r
forest <- function(d, ylab_col, title, xlab = "Risk ratio for 12-month persistence (95% CI)") {
  ggplot(d, aes(x = rr, xmin = rr_lo, xmax = rr_hi, y = forcats::fct_rev(forcats::fct_inorder(.data[[ylab_col]])))) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey50") +
    geom_pointrange(colour = "#1F6FB4", size = 0.35) +
    labs(x = xlab, y = NULL, title = title)
}
sg_plot <- subgroups |> mutate(label = paste0(subgroup, ": ", analysis, "  (p-int ", signif(p_interaction, 2), ")"))
ggsave(file.path(dir_figures, "fig6_subgroups.png"),
       forest(sg_plot, "label", "Figure 6. Persistence by prespecified subgroup (IPTW)"),
       width = 8, height = 4.5, dpi = 200, bg = "white")
ggsave(file.path(dir_figures, "fig7_sensitivity.png"),
       forest(sensitivity, "analysis", "Figure 7. Sensitivity analyses (risk ratio, tirzepatide vs semaglutide)",
              xlab = "Risk ratio (95% CI); S11 is the negative control outcome"),
       width = 8.5, height = 4.5, dpi = 200, bg = "white")
```

# Session information


``` r
sessionInfo()
```

```
## R version 4.4.1 (2024-06-14)
## Platform: x86_64-apple-darwin20
## Running under: macOS 15.7.9
## 
## Matrix products: default
## BLAS:   /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/lib/libRblas.0.dylib 
## LAPACK: /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.0
## 
## locale:
## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
## 
## time zone: America/New_York
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
##  [1] scales_1.4.0           patchwork_1.3.2        ggdag_0.2.13          
##  [4] dagitty_0.3-4          EValue_4.1.4           marginaleffects_0.32.0
##  [7] pscl_1.5.9             MASS_7.3-60.2          broom_1.0.11          
## [10] lmtest_0.9-40          zoo_1.8-12             sandwich_3.1-1        
## [13] survminer_0.5.1        ggpubr_0.6.1           ggplot2_4.0.0         
## [16] survival_3.6-4         cobalt_4.6.3           MatchIt_4.7.2         
## [19] WeightIt_1.7.0         officer_0.7.0          flextable_0.9.10      
## [22] tableone_0.13.2        gtsummary_2.4.0        janitor_2.2.1         
## [25] readr_2.1.5            lubridate_1.9.3        stringr_1.5.1         
## [28] tidyr_1.3.1            dplyr_1.1.4            data.table_1.17.0     
## [31] here_1.0.2            
## 
## loaded via a namespace (and not attached):
##   [1] mathjaxr_2.0-0          RColorBrewer_1.1-3      jsonlite_1.8.9         
##   [4] magrittr_2.0.3          farver_2.1.2            rmarkdown_2.28         
##   [7] ragg_1.3.3              vctrs_0.6.5             memoise_2.0.1          
##  [10] askpass_1.2.0           rstatix_0.7.2           forcats_1.0.0          
##  [13] htmltools_0.5.8.1       curl_5.2.3              survey_4.4-8           
##  [16] Formula_1.2-5           cachem_1.1.0            uuid_1.2-1             
##  [19] igraph_2.1.4            lifecycle_1.0.4         pkgconfig_2.0.3        
##  [22] Matrix_1.7-0            R6_2.5.1                fastmap_1.2.0          
##  [25] snakecase_0.11.1        digest_0.6.37           numDeriv_2016.8-1.1    
##  [28] rprojroot_2.1.1         textshaping_0.4.0       labeling_0.4.3         
##  [31] metadat_1.6-0           fansi_1.0.6             km.ci_0.5-6            
##  [34] timechange_0.3.0        polyclip_1.10-7         abind_1.4-8            
##  [37] compiler_4.4.1          bit64_4.5.2             fontquiver_0.2.1       
##  [40] withr_3.0.2             S7_0.2.0                backports_1.5.0        
##  [43] metafor_5.0-1           carData_3.0-5           viridis_0.6.5          
##  [46] DBI_1.2.3               chk_0.10.0              ggforce_0.5.0          
##  [49] MetaUtility_2.1.2       ggsignif_0.6.4          openssl_2.2.2          
##  [52] tools_4.4.1             zip_2.3.3               glue_1.8.0             
##  [55] nlme_3.1-164            grid_4.4.1              checkmate_2.3.3        
##  [58] generics_0.1.3          gtable_0.3.6            tzdb_0.5.0             
##  [61] KMsurv_0.1-6            hms_1.1.3               tidygraph_1.3.1        
##  [64] xml2_1.3.6              car_3.1-3               utf8_1.2.4             
##  [67] ggrepel_0.9.6           pillar_1.9.0            vroom_1.6.5            
##  [70] mitools_2.4             splines_4.4.1           tweenr_2.0.3           
##  [73] lattice_0.22-6          bit_4.5.0               tidyselect_1.2.1       
##  [76] fontLiberation_0.1.0    knitr_1.50              fontBitstreamVera_0.1.1
##  [79] gridExtra_2.3           V8_7.0.0                arg_0.2.0              
##  [82] xfun_0.53               graphlayouts_1.2.5      stringi_1.8.4          
##  [85] boot_1.3-30             evaluate_1.0.5          ggraph_2.2.2           
##  [88] gdtools_0.5.0           tibble_3.2.1            cli_3.6.5              
##  [91] xtable_1.8-4            systemfonts_1.3.1       survMisc_0.5.6         
##  [94] Rcpp_1.1.0              parallel_4.4.1          viridisLite_0.4.2      
##  [97] insight_1.4.2           purrr_1.0.2             crayon_1.5.3           
## [100] rlang_1.3.0
```
