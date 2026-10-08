# =============================================================================
# 04_clean_claims.R
# Purpose: clean pharmacy and medical claims (per decisions in the data quality log)
# Input:   raw_pharmacy.rds, raw_medical.rds, reference tables
# Output:  04_data_derived/pharmacy_clean.rds, medical_clean.rds
# =============================================================================
source(here::here("05_code", "00_setup.R"))

# TODO: write after the SAP is finalized.
