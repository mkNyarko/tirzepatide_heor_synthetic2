# =============================================================================
# 08_table1_and_weighting.R
# Purpose: Table 1, propensity score model, weights and covariate balance
# Input:   04_data_derived/analytic.rds
# Output:  04_data_derived/analytic_weighted.rds, 06_output/tables/table1.csv,
#          balance and overlap figures
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- ps-formula ----
analytic <- readRDS(file.path(dir_derived, "analytic.rds"))

# Adjustment set from the DAG (SAP section 7)
covs <- c("age", "sex", "region", "plan_type", "index_qtr", "obesity_class",
          "hypertension", "dyslipidemia", "sleep_apnea", "prediabetes", "masld", "osteoarthritis",
          "depression", "anxiety", "gerd", "ascvd", "heart_failure", "ckd", "pcos", "hypothyroid",
          "gallbladder", "pancreatitis", "prior_aom", "metformin", "antihypertensive", "statin",
          "antidepressant", "n_generics", "bariatric_hx", "endo_visit", "base_any_ip", "base_any_ed",
          "base_op_visits", "log_base_cost")
ps_formula <- reformulate(covs, response = "treat")

## ---- ps-weights ----
# Propensity score (logistic regression) and stabilized ATE weights
w_ate <- WeightIt::weightit(ps_formula, data = analytic, method = "glm",
                            estimand = "ATE", stabilize = TRUE)
summary(w_ate)
analytic$ps <- w_ate$ps
analytic$w  <- w_ate$weights
saveRDS(analytic, file.path(dir_derived, "analytic_weighted.rds"))
saveRDS(list(covs = covs, ps_formula = ps_formula), file.path(dir_derived, "ps_spec.rds"))

## ---- ps-balance ----
bal <- cobalt::bal.tab(w_ate, un = TRUE, binary = "std", continuous = "std",
                       thresholds = c(m = 0.1, v = 2), stats = c("m", "v"))
print(bal)
bal_df <- bal$Balance |>
  tibble::rownames_to_column("covariate") |>
  select(covariate, smd_unweighted = Diff.Un, smd_weighted = Diff.Adj,
         var_ratio_unweighted = V.Ratio.Un, var_ratio_weighted = V.Ratio.Adj)
readr::write_csv(bal_df, file.path(dir_tables, "balance_smd.csv"))
max_smd <- max(abs(bal_df$smd_weighted), na.rm = TRUE)
message("Largest absolute weighted SMD: ", round(max_smd, 3),
        if (max_smd < 0.1) "  -> balance achieved (all < 0.10)" else "  -> IMBALANCE: revise PS model")
ess <- cobalt::bal.tab(w_ate)$Observations
print(ess)

## ---- table1 ----
# Table 1: unweighted and IPTW-weighted characteristics with SMDs
wmean <- function(x, w) sum(x * w) / sum(w)
wsd   <- function(x, w) sqrt(sum(w * (x - wmean(x, w))^2) / sum(w))
t1_vars <- c(covs, "base_med_cost", "base_rx_cost", "base_total_cost")
make_rows <- function(v) {
  x <- analytic[[v]]
  if (is.factor(x) || is.character(x)) {
    lv <- levels(factor(x))
    purrr::map_dfr(lv, function(l) {
      ind <- as.numeric(x == l)
      tibble(variable = v, level = l, type = "pct",
             tirz = mean(ind[analytic$treat == 1]) * 100, sema = mean(ind[analytic$treat == 0]) * 100,
             tirz_w = wmean(ind[analytic$treat == 1], analytic$w[analytic$treat == 1]) * 100,
             sema_w = wmean(ind[analytic$treat == 0], analytic$w[analytic$treat == 0]) * 100,
             tirz_sd = NA, sema_sd = NA)
    })
  } else {
    x <- as.numeric(x); t1 <- analytic$treat == 1; t0 <- !t1
    tibble(variable = v, level = "", type = if (is.logical(analytic[[v]])) "pct" else "mean",
           tirz = mean(x[t1]) * if (is.logical(analytic[[v]])) 100 else 1,
           sema = mean(x[t0]) * if (is.logical(analytic[[v]])) 100 else 1,
           tirz_w = wmean(x[t1], analytic$w[t1]) * if (is.logical(analytic[[v]])) 100 else 1,
           sema_w = wmean(x[t0], analytic$w[t0]) * if (is.logical(analytic[[v]])) 100 else 1,
           tirz_sd = if (is.logical(analytic[[v]])) NA else sd(x[t1]),
           sema_sd = if (is.logical(analytic[[v]])) NA else sd(x[t0]))
  }
}
table1 <- purrr::map_dfr(t1_vars, make_rows) |>
  mutate(smd_unweighted = NA_real_, smd_weighted = NA_real_)
# attach SMDs from cobalt (names: variable, variable_TRUE or variable_level)
for (i in seq_len(nrow(table1))) {
  key <- c(paste0(table1$variable[i], "_", table1$level[i]), paste0(table1$variable[i], "_TRUE"), table1$variable[i])
  hit <- bal_df[bal_df$covariate %in% key, ]
  if (nrow(hit)) { table1$smd_unweighted[i] <- hit$smd_unweighted[1]; table1$smd_weighted[i] <- hit$smd_weighted[1] }
}
table1 <- bind_rows(
  tibble(variable = "N patients", level = "", type = "n",
         tirz = sum(analytic$treat == 1), sema = sum(analytic$treat == 0),
         tirz_w = sum(analytic$w[analytic$treat == 1]), sema_w = sum(analytic$w[analytic$treat == 0])),
  table1)
readr::write_csv(table1, file.path(dir_tables, "table1_baseline.csv"))
print(table1 |> mutate(across(where(is.numeric), ~ round(.x, 2))), n = Inf, width = 200)

## ---- ps-figures ----
p_overlap <- ggplot(analytic, aes(x = ps, fill = drug)) +
  geom_density(alpha = 0.45, colour = NA) +
  scale_fill_manual(values = col_drug, name = NULL) +
  labs(x = "Propensity score (probability of starting tirzepatide)", y = "Density",
       title = "Figure 2. Propensity score overlap") +
  theme(legend.position = "bottom")
ggsave(file.path(dir_figures, "fig2_ps_overlap.png"), p_overlap, width = 7, height = 4.5, dpi = 200, bg = "white")

p_love <- cobalt::love.plot(w_ate, binary = "std", abs = TRUE, thresholds = c(m = 0.1),
                            var.order = "unadjusted", line = FALSE, stars = "none",
                            colors = c("#B5B5B5", "#1F6FB4"), shapes = c("circle", "triangle"),
                            sample.names = c("Unweighted", "IPTW")) +
  labs(title = "Figure 3. Covariate balance before and after weighting")
ggsave(file.path(dir_figures, "fig3_love_plot.png"), p_love, width = 7.5, height = 9, dpi = 200, bg = "white")

summary(analytic$w)
