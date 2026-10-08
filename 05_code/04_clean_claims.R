# =============================================================================
# 04_clean_claims.R
# Purpose: clean pharmacy and medical claims (per decisions in the data quality log)
# Input:   raw_pharmacy.rds, raw_medical.rds, reference tables
# Output:  04_data_derived/pharmacy_clean.rds, medical_clean.rds
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- clean-pharmacy ----
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

## ---- clean-medical ----
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
