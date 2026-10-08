# =============================================================================
# 02_data_quality_review.R
# Purpose: profile the raw tables and log every data problem found (duplicates, reversals, code formats, implausible values, enrollment overlaps)
# Input:   04_data_derived/raw_*.rds
# Output:  06_output/tables/data_quality_log.csv
# =============================================================================
source(here::here("05_code", "00_setup.R"))

# TODO: write after the SAP is finalized.
