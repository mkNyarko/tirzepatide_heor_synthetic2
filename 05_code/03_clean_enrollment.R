# =============================================================================
# 03_clean_enrollment.R
# Purpose: clean members; collapse enrollment segments and flag continuous medical + pharmacy coverage
# Input:   raw_members.rds, raw_enrollment.rds
# Output:  04_data_derived/members_clean.rds, enrollment_spans.rds, enrollment_segments.rds
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- clean-members ----
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

## ---- clean-enrollment ----
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
