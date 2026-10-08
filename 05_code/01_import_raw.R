# =============================================================================
# 01_import_raw.R
# Purpose: read the raw extract exactly as delivered, stack the yearly files,
#          and save R copies. NO cleaning or derivation happens here.
# Output:  04_data_derived/raw_*.rds
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- import-raw ----

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

## ---- import-check ----
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
