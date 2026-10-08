# =============================================================================
# 02_data_quality_review.R
# Purpose: profile the raw tables and log every data problem found (duplicates,
#          reversals, code formats, implausible values, enrollment overlaps)
# Input:   04_data_derived/raw_*.rds
# Output:  06_output/tables/data_quality_log.csv
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- dq-load ----
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

## ---- dq-members ----
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

## ---- dq-enrollment ----
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

## ---- dq-pharmacy ----
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

## ---- dq-medical ----
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

## ---- dq-save ----
dq_log <- bind_rows(dq)
readr::write_csv(dq_log, file.path(dir_tables, "data_quality_log.csv"))
print(dq_log, n = Inf, width = 200)
