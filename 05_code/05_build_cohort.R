# =============================================================================
# 05_build_cohort.R
# Purpose: identify index dates and apply inclusion/exclusion criteria; produce attrition counts
# Input:   cleaned tables
# Output:  04_data_derived/cohort.rds, dx_long.rds, 06_output/tables/attrition.csv,
#          06_output/figures/fig1_cohort_flow.png
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- cohort-load ----
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

## ---- cohort-codes ----
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

## ---- cohort-index ----
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

## ---- cohort-criteria ----
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

## ---- cohort-plan ----
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

## ---- cohort-attrition ----
attrition_tbl <- bind_rows(attrition) |>
  mutate(excluded = lag(n) - n)
readr::write_csv(attrition_tbl, file.path(dir_tables, "attrition.csv"))
print(attrition_tbl, width = 200)

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
