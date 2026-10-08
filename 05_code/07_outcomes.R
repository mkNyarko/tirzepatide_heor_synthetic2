# =============================================================================
# 07_outcomes.R
# Purpose: derive persistence, PDC, switching, utilization and cost outcomes over 365-day follow-up
# Input:   cohort.rds, covariates.rds, cleaned claims, encounters.rds, med_claims.rds
# Output:  04_data_derived/outcomes.rds, analytic.rds
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- out-load ----
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

## ---- out-persistence-function ----
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

## ---- out-persistence ----
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

## ---- out-utilization-costs ----
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

## ---- out-assemble ----
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
