# =============================================================================
# 00_setup.R
# Project: Tirzepatide vs semaglutide 2.4 mg - persistence and costs (synthetic claims)
# Purpose: install/load packages and define project paths. Run once per session.
# Open the project by double-clicking HEOR_Tirzepatide_Project.Rproj so paths resolve.
# =============================================================================

pkgs <- c(
  # data handling
  "here", "data.table", "dplyr", "tidyr", "stringr", "lubridate", "readr", "janitor",
  # descriptive tables
  "gtsummary", "tableone", "flextable", "officer",
  # confounding adjustment and balance
  "WeightIt", "MatchIt", "cobalt",
  # models
  "survival", "survminer", "sandwich", "lmtest", "broom", "MASS", "pscl",
  # sensitivity analysis
  "EValue",
  # DAG
  "dagitty", "ggdag",
  # figures
  "ggplot2", "patchwork", "scales"
)
to_install <- setdiff(pkgs, rownames(installed.packages()))
if (length(to_install) > 0) install.packages(to_install)
invisible(lapply(pkgs, library, character.only = TRUE))

# ---- paths ------------------------------------------------------------------
dir_raw     <- here::here("02_data_raw")
dir_ref     <- here::here("03_reference")
dir_derived <- here::here("04_data_derived")
dir_tables  <- here::here("06_output", "tables")
dir_figures <- here::here("06_output", "figures")

# ---- study calendar (from the protocol) --------------------------------------
data_start   <- as.Date("2023-01-01")
data_end     <- as.Date("2026-06-30")
index_start  <- as.Date("2024-01-01")
index_end    <- as.Date("2025-06-30")
baseline_days  <- 365
followup_days  <- 365

set.seed(20261007)
message("Setup complete. Raw data in: ", dir_raw)
