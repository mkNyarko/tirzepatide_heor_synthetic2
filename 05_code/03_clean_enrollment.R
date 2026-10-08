# =============================================================================
# 03_clean_enrollment.R
# Purpose: collapse enrollment segments and flag continuous medical + pharmacy coverage
# Input:   raw_enrollment.rds
# Output:  04_data_derived/enrollment_clean.rds
# =============================================================================
source(here::here("05_code", "00_setup.R"))

# TODO: write after the SAP is finalized.
