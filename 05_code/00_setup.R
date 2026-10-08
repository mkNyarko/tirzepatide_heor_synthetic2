# =============================================================================
# 00_setup.R
# Project: Tirzepatide vs semaglutide 2.4 mg - persistence and costs (synthetic claims)
# Purpose: install/load packages and define project paths. Run once per session.
# Open the project by double-clicking HEOR_Tirzepatide_Project.Rproj so paths resolve.
# Environment used for the reference run: R 4.4.1 (x86_64-apple-darwin20),
#   macOS 15.7.9, locale en_US.UTF-8, time zone America/New_York.
# =============================================================================

## ---- setup-packages ----
pkgs <- c(
  # data handling
  "here", "data.table", "dplyr", "tidyr", "stringr", "lubridate", "readr", "janitor",
  # descriptive tables
  "gtsummary", "tableone", "flextable", "officer",
  # confounding adjustment and balance
  "WeightIt", "MatchIt", "cobalt",
  # models
  "survival", "survminer", "sandwich", "lmtest", "broom", "MASS", "pscl", "marginaleffects",
  # sensitivity analysis
  "EValue",
  # DAG
  "dagitty", "ggdag",
  # figures
  "ggplot2", "patchwork", "scales"
)
to_install <- setdiff(pkgs, rownames(installed.packages()))
if (length(to_install) > 0) install.packages(to_install, repos = "https://cloud.r-project.org")
suppressPackageStartupMessages(invisible(lapply(pkgs, library, character.only = TRUE)))
# MASS masks dplyr::select; make sure select() means dplyr::select()
select <- dplyr::select

## ---- setup-paths ----
dir_raw     <- here::here("02_data_raw")
dir_ref     <- here::here("03_reference")
dir_derived <- here::here("04_data_derived")
dir_tables  <- here::here("06_output", "tables")
dir_figures <- here::here("06_output", "figures")
for (d in c(dir_derived, dir_tables, dir_figures)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

# ---- study calendar (from the protocol) --------------------------------------
data_start    <- as.Date("2023-01-01")
data_end      <- as.Date("2026-06-30")
index_start   <- as.Date("2024-01-01")
index_end     <- as.Date("2025-06-30")
baseline_days <- 365   # baseline = index - 365 to index - 1
followup_days <- 365   # follow-up = index to index + 364
gap_days      <- 60    # primary persistence grace period (SAP section 6.1)
enroll_gap_allowed <- 30  # enrollment gaps of <= 30 days are bridged (SAP section 4)

set.seed(20261007)
theme_set(theme_minimal(base_size = 11))
col_drug <- c("Tirzepatide" = "#1F6FB4", "Semaglutide 2.4 mg" = "#D9822B")
message("Setup complete. Raw data in: ", dir_raw)
