# =============================================================================
# 06_baseline_covariates.R
# Purpose: derive baseline covariates over the 365-day pre-index period
# Input:   cohort.rds, cleaned claims, dx_long.rds
# Output:  04_data_derived/covariates.rds, encounters.rds, med_claims.rds
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- cov-load ----
cohort  <- readRDS(file.path(dir_derived, "cohort.rds"))
rx      <- readRDS(file.path(dir_derived, "pharmacy_clean.rds"))
med     <- readRDS(file.path(dir_derived, "medical_clean.rds"))
dx_long <- readRDS(file.path(dir_derived, "dx_long.rds"))

ids <- cohort |> select(member_id, index_date)
# Keep only cohort members' claims, with each claim's day relative to index (0 = index date)
rx_c  <- rx  |> inner_join(ids, by = "member_id") |> mutate(day = as.integer(fill_date - index_date))
med_c <- med |> inner_join(ids, by = "member_id") |> mutate(day = as.integer(service_from_date - index_date))
dx_c  <- dx_long |> inner_join(ids, by = "member_id") |> mutate(day = as.integer(date - index_date))

## ---- cov-encounters ----
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

## ---- cov-diagnoses ----
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

## ---- cov-utilization ----
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

## ---- cov-medications ----
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

## ---- cov-assemble ----
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
