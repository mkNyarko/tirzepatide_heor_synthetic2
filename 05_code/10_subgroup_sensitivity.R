# =============================================================================
# 10_subgroup_sensitivity.R
# Purpose: prespecified subgroup, interaction, sensitivity and bias analyses
# Input:   04_data_derived/analytic_weighted.rds
# Output:  06_output/tables/table4_subgroups.csv, table5_sensitivity.csv, evalues.csv,
#          figures 6-7
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- sens-helpers ----
analytic <- readRDS(file.path(dir_derived, "analytic_weighted.rds"))
ps_spec  <- readRDS(file.path(dir_derived, "ps_spec.rds"))

robust_ci <- function(fit, term = "treat", exp = FALSE) {
  est <- coef(fit)[[term]]; se <- sqrt(sandwich::vcovHC(fit, type = "HC0")[term, term])
  ci  <- est + c(-1, 1) * qnorm(0.975) * se
  if (exp) c(est = exp(est), lo = exp(ci[1]), hi = exp(ci[2])) else c(est = est, lo = ci[1], hi = ci[2])
}
# Weighted persistence comparison in data `d` with weights column `w`
persist_effect <- function(d, label, y = "persistent", wcol = "w") {
  d$y <- as.numeric(d[[y]]); d$wt <- d[[wcol]]
  rd <- robust_ci(lm(y ~ treat, data = d, weights = wt))
  rr <- robust_ci(glm(y ~ treat, data = d, weights = wt, family = quasipoisson(link = "log")), exp = TRUE)
  tibble(analysis = label, n = nrow(d),
         tirz = 100 * weighted.mean(d$y[d$treat == 1], d$wt[d$treat == 1]),
         sema = 100 * weighted.mean(d$y[d$treat == 0], d$wt[d$treat == 0]),
         rd = 100 * rd[["est"]], rd_lo = 100 * rd[["lo"]], rd_hi = 100 * rd[["hi"]],
         rr = rr[["est"]], rr_lo = rr[["lo"]], rr_hi = rr[["hi"]])
}
# Re-estimate stabilized ATE weights within a subset (the population changes)
reweight <- function(d, drop = character()) {
  f <- reformulate(setdiff(ps_spec$covs, drop), response = "treat")
  d$w <- WeightIt::weightit(f, data = droplevels(d), method = "glm", estimand = "ATE", stabilize = TRUE)$weights
  d
}

## ---- subgroups ----
subgroup_vars <- c(obesity_class = "Obesity class", sex = "Sex", age_group = "Age group", cdhp = "Plan type")
subgroups <- purrr::imap_dfr(subgroup_vars, function(lab, v) {
  # interaction test: weighted log-link model with treat x subgroup, robust Wald test (multi-df)
  fit <- glm(reformulate(c("treat", v, paste0("treat:", v)), response = "as.numeric(persistent)"),
             data = analytic, weights = w, family = quasipoisson(link = "log"))
  ix  <- grep("^treat:", names(coef(fit)))
  V   <- sandwich::vcovHC(fit, type = "HC0")[ix, ix, drop = FALSE]
  b   <- coef(fit)[ix]
  p_int <- pchisq(as.numeric(t(b) %*% solve(V) %*% b), df = length(ix), lower.tail = FALSE)
  purrr::map_dfr(levels(analytic[[v]]), function(l) {
    persist_effect(analytic[analytic[[v]] == l, ], label = l)
  }) |> mutate(subgroup = lab, p_interaction = p_int, .before = 1)
})
readr::write_csv(subgroups, file.path(dir_tables, "table4_subgroups.csv"))
print(subgroups, width = 200)

## ---- sensitivity ----
primary <- persist_effect(analytic, "Primary: IPTW, 60-day gap")

# S4: 1:1 nearest-neighbour matching on the logit PS, caliper 0.2 SD (ATT)
m_out <- MatchIt::matchit(ps_spec$ps_formula, data = analytic, method = "nearest",
                          distance = "glm", link = "linear.logit", caliper = 0.2, estimand = "ATT")
matched <- MatchIt::match.data(m_out)
max_smd_matched <- max(abs(cobalt::bal.tab(m_out, binary = "std")$Balance$Diff.Adj), na.rm = TRUE)

# S5: weights truncated at the 1st and 99th percentiles
trimmed <- analytic |> mutate(w = pmin(pmax(w, quantile(w, 0.01)), quantile(w, 0.99)))

# S6: doubly robust g-computation (weighted outcome model with all covariates)
dr_fit <- glm(update(ps_spec$ps_formula, as.numeric(persistent) ~ treat + .), data = analytic,
              weights = w, family = quasibinomial)
dr_rd <- marginaleffects::avg_comparisons(dr_fit, variables = "treat", wts = "w", vcov = "HC0")
dr_rr <- marginaleffects::avg_comparisons(dr_fit, variables = "treat", wts = "w", vcov = "HC0",
                                          comparison = "lnratioavg", transform = exp)

sensitivity <- bind_rows(
  primary,
  persist_effect(analytic, "S1: 30-day gap", y = "persistent_g30"),
  persist_effect(analytic, "S2: 90-day gap", y = "persistent_g90"),
  persist_effect(analytic, "S3: Either drug (switching allowed)", y = "persistent_class"),
  persist_effect(matched, "S4: 1:1 PS matching (ATT)", wcol = "weights"),
  persist_effect(trimmed, "S5: Weights trimmed at 1st/99th percentile"),
  tibble(analysis = "S6: Doubly robust (IPTW + outcome model)", n = nrow(analytic),
         rd = 100 * dr_rd$estimate, rd_lo = 100 * dr_rd$conf.low, rd_hi = 100 * dr_rd$conf.high,
         rr = dr_rr$estimate, rr_lo = dr_rr$conf.low, rr_hi = dr_rr$conf.high),
  persist_effect(reweight(filter(analytic, !metformin)), "S7: Excluding baseline metformin users"),
  persist_effect(reweight(filter(analytic, obesity_class != "Unknown")), "S8: Recorded obesity class only"),
  persist_effect(analytic, "S11: Negative control outcome - cancer screening", y = "neg_control")
)
print(sensitivity, width = 200)
message("Matched pairs: ", sum(matched$treat == 1), "; largest SMD after matching: ", round(max_smd_matched, 3))

## ---- sensitivity-costs ----
# S9: costs winsorized at the 99th percentile (all patients pooled)
wins <- function(x) pmin(x, quantile(x, 0.99))
cost_sens <- purrr::map_dfr(c("cost_medical", "cost_pharmacy", "cost_total"), function(v) {
  x <- analytic[[v]]; xw <- wins(x); t1 <- analytic$treat == 1
  tibble(outcome = v,
         diff_raw  = weighted.mean(x[t1], analytic$w[t1]) - weighted.mean(x[!t1], analytic$w[!t1]),
         diff_wins = weighted.mean(xw[t1], analytic$w[t1]) - weighted.mean(xw[!t1], analytic$w[!t1]),
         ratio_wins = weighted.mean(xw[t1], analytic$w[t1]) / weighted.mean(xw[!t1], analytic$w[!t1]))
})
readr::write_csv(cost_sens, file.path(dir_tables, "table5b_cost_sensitivity.csv"))
print(cost_sens)

## ---- evalues ----
# S10: E-values (minimum strength of unmeasured confounding, on the RR scale, needed to explain away
# the estimate and its confidence limit). Persistence is common (>15%), so the HR is converted.
cox <- coxph(Surv(time_to_disc, discontinued) ~ treat, data = analytic, weights = w, robust = TRUE)
hr  <- summary(cox)$conf.int
ev_rr <- EValue::evalues.RR(primary$rr, primary$rr_lo, primary$rr_hi)
ev_hr <- EValue::evalues.HR(hr[1, 1], hr[1, 3], hr[1, 4], rare = FALSE)
evalues <- tibble(
  estimate = c("RR persistent at 12 months", "HR discontinuation"),
  point = c(primary$rr, hr[1, 1]), lo = c(primary$rr_lo, hr[1, 3]), hi = c(primary$rr_hi, hr[1, 4]),
  evalue_point = c(ev_rr["E-values", "point"], ev_hr["E-values", "point"]),
  evalue_ci    = c(ev_rr["E-values", "lower"], ev_hr["E-values", "upper"]))
readr::write_csv(evalues, file.path(dir_tables, "evalues.csv"))
print(evalues)
readr::write_csv(sensitivity, file.path(dir_tables, "table5_sensitivity.csv"))

## ---- sens-figures ----
forest <- function(d, ylab_col, title, xlab = "Risk ratio for 12-month persistence (95% CI)") {
  ggplot(d, aes(x = rr, xmin = rr_lo, xmax = rr_hi, y = forcats::fct_rev(forcats::fct_inorder(.data[[ylab_col]])))) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey50") +
    geom_pointrange(colour = "#1F6FB4", size = 0.35) +
    labs(x = xlab, y = NULL, title = title)
}
sg_plot <- subgroups |> mutate(label = paste0(subgroup, ": ", analysis, "  (p-int ", signif(p_interaction, 2), ")"))
ggsave(file.path(dir_figures, "fig6_subgroups.png"),
       forest(sg_plot, "label", "Figure 6. Persistence by prespecified subgroup (IPTW)"),
       width = 8, height = 4.5, dpi = 200, bg = "white")
ggsave(file.path(dir_figures, "fig7_sensitivity.png"),
       forest(sensitivity, "analysis", "Figure 7. Sensitivity analyses (risk ratio, tirzepatide vs semaglutide)",
              xlab = "Risk ratio (95% CI); S11 is the negative control outcome"),
       width = 8.5, height = 4.5, dpi = 200, bg = "white")
