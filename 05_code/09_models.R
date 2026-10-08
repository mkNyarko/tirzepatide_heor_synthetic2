# =============================================================================
# 09_models.R
# Purpose: primary and secondary outcome models (IPTW, robust variance), model checks
# Input:   04_data_derived/analytic_weighted.rds
# Output:  06_output/tables/table2_persistence.csv, table3_hcru_costs.csv, model_checks.txt,
#          figures 4-5
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- models-helpers ----
analytic <- readRDS(file.path(dir_derived, "analytic_weighted.rds"))
ps_spec  <- readRDS(file.path(dir_derived, "ps_spec.rds"))

robust_ci <- function(fit, term = "treat", exp = FALSE) {
  est <- coef(fit)[[term]]; se <- sqrt(sandwich::vcovHC(fit, type = "HC0")[term, term])
  ci  <- est + c(-1, 1) * qnorm(0.975) * se
  p   <- 2 * pnorm(-abs(est / se))
  if (exp) c(est = exp(est), lo = exp(ci[1]), hi = exp(ci[2]), p = p) else c(est = est, lo = ci[1], hi = ci[2], p = p)
}
wmean_by <- function(y, d = analytic) {
  c(tirz = weighted.mean(y[d$treat == 1], d$w[d$treat == 1]),
    sema = weighted.mean(y[d$treat == 0], d$w[d$treat == 0]))
}
# Binary outcome: weighted proportions, risk difference (linear probability) and risk ratio (log link)
binary_effect <- function(y_name, d = analytic, label = y_name) {
  d$y <- as.numeric(d[[y_name]])
  rd <- robust_ci(lm(y ~ treat, data = d, weights = w))
  rr <- robust_ci(glm(y ~ treat, data = d, weights = w, family = quasipoisson(link = "log")), exp = TRUE)
  m  <- wmean_by(d$y, d)
  tibble(outcome = label, tirz = m[["tirz"]] * 100, sema = m[["sema"]] * 100,
         diff = rd[["est"]] * 100, diff_lo = rd[["lo"]] * 100, diff_hi = rd[["hi"]] * 100,
         ratio = rr[["est"]], ratio_lo = rr[["lo"]], ratio_hi = rr[["hi"]], p = rr[["p"]], measure = "RD (pct points) / RR")
}

## ---- models-persistence ----
# Primary outcome: persistence at 12 months
primary <- binary_effect("persistent", label = "Persistent at 12 months (60-day gap)")
print(primary)

# Time to discontinuation: weighted Kaplan-Meier and weighted Cox (robust variance)
km  <- survfit(Surv(time_to_disc, discontinued) ~ drug, data = analytic, weights = w)
cox <- coxph(Surv(time_to_disc, discontinued) ~ treat, data = analytic, weights = w, robust = TRUE)
hr  <- summary(cox)$conf.int
ph_test <- cox.zph(cox)
print(summary(cox)); print(ph_test)

# Restricted mean time on treatment over 365 days (area under each weighted KM curve)
rmst <- function(fit) {
  s <- summary(fit, times = c(0, fit$time), extend = TRUE)
  tapply(seq_along(s$time), s$strata, function(i) {
    t <- c(s$time[i], 365); S <- s$surv[i]
    keep <- t[-length(t)] < 365
    sum(diff(pmin(t, 365))[keep] * S[keep])
  })
}
rmst_km <- rmst(km); print(rmst_km)

p_km <- survminer::ggsurvplot(km, data = analytic, conf.int = TRUE, censor = FALSE,
                              palette = unname(col_drug[c("Semaglutide 2.4 mg", "Tirzepatide")]),
                              legend.labs = c("Semaglutide 2.4 mg", "Tirzepatide"), legend.title = "",
                              xlab = "Days since index", ylab = "Proportion still on index drug",
                              break.time.by = 60, xlim = c(0, 365), ylim = c(0, 1),
                              title = "Figure 4. Time to discontinuation (IPTW-weighted Kaplan-Meier)",
                              ggtheme = theme_minimal(base_size = 11))
ggsave(file.path(dir_figures, "fig4_km_discontinuation.png"), p_km$plot, width = 7.5, height = 5, dpi = 200, bg = "white")

## ---- models-adherence ----
pdc_fit <- lm(pdc ~ treat, data = analytic, weights = w)
pdc_eff <- robust_ci(pdc_fit)
pdc_m   <- wmean_by(analytic$pdc)
table2 <- bind_rows(
  primary,
  tibble(outcome = "Time to discontinuation (hazard ratio)", ratio = hr[1, "exp(coef)"],
         ratio_lo = hr[1, "lower .95"], ratio_hi = hr[1, "upper .95"],
         p = summary(cox)$coefficients[1, "Pr(>|z|)"], measure = "HR"),
  tibble(outcome = "Restricted mean days on treatment (0-365)", tirz = rmst_km[[2]], sema = rmst_km[[1]],
         diff = rmst_km[[2]] - rmst_km[[1]], measure = "Mean difference (days); CI from bootstrap"),
  tibble(outcome = "PDC, mean (%)", tirz = pdc_m[["tirz"]] * 100, sema = pdc_m[["sema"]] * 100,
         diff = pdc_eff[["est"]] * 100, diff_lo = pdc_eff[["lo"]] * 100, diff_hi = pdc_eff[["hi"]] * 100,
         p = pdc_eff[["p"]], measure = "Mean difference (pct points)"),
  binary_effect("pdc80", label = "Adherent (PDC >= 80%)"),
  binary_effect("switched", label = "Switched to the other drug")
)

## ---- models-utilization ----
table3_bin <- bind_rows(
  binary_effect("any_ip", label = "Any inpatient admission"),
  binary_effect("any_ed", label = "Any emergency department visit")
)
count_effect <- function(y_name, label) {
  f  <- reformulate("treat", response = y_name)
  nb <- MASS::glm.nb(f, data = analytic, weights = w)
  po <- glm(f, data = analytic, weights = w, family = poisson)
  dispersion <- sum(residuals(po, type = "pearson")^2) / po$df.residual
  rr <- robust_ci(nb, exp = TRUE); m <- wmean_by(analytic[[y_name]])
  list(row = tibble(outcome = label, tirz = m[["tirz"]], sema = m[["sema"]], diff = m[["tirz"]] - m[["sema"]],
                    ratio = rr[["est"]], ratio_lo = rr[["lo"]], ratio_hi = rr[["hi"]], p = rr[["p"]],
                    measure = "Mean difference / rate ratio (negative binomial)"),
       dispersion = dispersion, theta = nb$theta)
}
op  <- count_effect("n_outpatient", "Outpatient visits, mean")
opo <- count_effect("n_outpatient_obesity", "Obesity-related outpatient visits, mean")

## ---- models-costs ----
# Gamma GLM (log link) for strictly positive costs; two-part model for medical costs (zeros allowed)
cost_ratio <- function(y_name) {
  robust_ci(glm(reformulate("treat", response = y_name), data = analytic, weights = w,
                family = Gamma(link = "log")), exp = TRUE)
}
cr_total <- cost_ratio("cost_total"); cr_rx <- cost_ratio("cost_pharmacy")
analytic$any_med_cost <- analytic$cost_medical > 0
part1 <- glm(any_med_cost ~ treat, data = analytic, weights = w, family = quasibinomial)
part2 <- glm(cost_medical ~ treat, data = subset(analytic, cost_medical > 0), weights = w, family = Gamma(link = "log"))
twopart_mean <- function(t) {
  nd <- data.frame(treat = t)
  predict(part1, nd, type = "response") * predict(part2, nd, type = "response")
}
cr_med <- c(est = twopart_mean(1) / twopart_mean(0))
cost_means <- sapply(c("cost_medical", "cost_pharmacy", "cost_total", "cost_study_drug"), function(v) wmean_by(analytic[[v]]))
print(round(cost_means))

## ---- models-bootstrap ----
# Bootstrap (500 replicates): re-estimate the propensity score and weights in each resample,
# then recompute weighted mean cost differences and the restricted mean time on treatment
boot_once <- function(i) {
  d <- analytic[sample.int(nrow(analytic), replace = TRUE), ]
  ps <- fitted(glm(ps_spec$ps_formula, data = d, family = binomial))
  pt <- mean(d$treat)
  d$w <- ifelse(d$treat == 1, pt / ps, (1 - pt) / (1 - ps))
  m <- sapply(c("cost_medical", "cost_pharmacy", "cost_total"), function(v) {
    x <- wmean_by(d[[v]], d); x[["tirz"]] - x[["sema"]] })
  r <- rmst(survfit(Surv(time_to_disc, discontinued) ~ drug, data = d, weights = w))
  c(m, rmst = r[[2]] - r[[1]])
}
set.seed(20261007)
boot <- do.call(rbind, lapply(1:500, boot_once))
boot_ci <- apply(boot, 2, quantile, probs = c(0.025, 0.975))
print(round(boot_ci, 1))
saveRDS(boot, file.path(dir_derived, "bootstrap_replicates.rds"))

table2$diff_lo[table2$outcome == "Restricted mean days on treatment (0-365)"] <- boot_ci[1, "rmst"]
table2$diff_hi[table2$outcome == "Restricted mean days on treatment (0-365)"] <- boot_ci[2, "rmst"]

cost_row <- function(v, label, ratio) {
  tibble(outcome = label, tirz = cost_means["tirz", v], sema = cost_means["sema", v],
         diff = cost_means["tirz", v] - cost_means["sema", v],
         diff_lo = boot_ci[1, v], diff_hi = boot_ci[2, v],
         ratio = ratio[["est"]], ratio_lo = if (length(ratio) > 1) ratio[["lo"]] else NA,
         ratio_hi = if (length(ratio) > 1) ratio[["hi"]] else NA, p = if (length(ratio) > 1) ratio[["p"]] else NA,
         measure = "Mean difference $ (bootstrap CI) / cost ratio")
}
table3 <- bind_rows(
  table3_bin, op$row, opo$row,
  cost_row("cost_medical", "Medical cost, mean $ (two-part model)", cr_med),
  cost_row("cost_pharmacy", "Pharmacy cost, mean $ (gamma GLM)", cr_rx),
  cost_row("cost_total", "Total cost, mean $ (gamma GLM)", cr_total),
  tibble(outcome = "  of which study-drug pharmacy cost, mean $", tirz = cost_means["tirz", "cost_study_drug"],
         sema = cost_means["sema", "cost_study_drug"],
         diff = cost_means["tirz", "cost_study_drug"] - cost_means["sema", "cost_study_drug"], measure = "Descriptive")
)
readr::write_csv(table2, file.path(dir_tables, "table2_persistence_adherence.csv"))
readr::write_csv(table3, file.path(dir_tables, "table3_hcru_costs.csv"))
print(table2, width = 200); print(table3, width = 200)

## ---- models-checks ----
# Modified Park test on a covariate-adjusted weighted gamma model of total cost:
# slope ~ 2 supports the gamma variance function (0 = Gaussian, 1 = Poisson, 3 = inverse Gaussian)
adj_cost <- glm(update(ps_spec$ps_formula, cost_total ~ treat + .), data = analytic, weights = w,
                family = Gamma(link = "log"))
mu <- fitted(adj_cost)
park <- glm(I((analytic$cost_total - mu)^2) ~ log(mu), family = quasipoisson(link = "log"), weights = analytic$w)
park_slope <- coef(park)[2]
checks <- c(
  sprintf("Proportional hazards (cox.zph) global p = %.3f", ph_test$table["GLOBAL", "p"]),
  sprintf("Modified Park test slope (total cost) = %.2f (gamma ~ 2)", park_slope),
  sprintf("Poisson dispersion, outpatient visits = %.2f (>1 = overdispersion; negative binomial theta = %.2f)",
          op$dispersion, op$theta),
  sprintf("Poisson dispersion, obesity-related visits = %.2f", opo$dispersion),
  sprintf("Share of patients with $0 medical cost = %.1f%%", 100 * mean(analytic$cost_medical == 0))
)
writeLines(checks, file.path(dir_tables, "model_checks.txt")); cat(checks, sep = "\n")
png(file.path(dir_figures, "figS1_schoenfeld.png"), width = 1400, height = 900, res = 200)
plot(ph_test, resid = FALSE, main = "Scaled Schoenfeld residuals: tirzepatide vs semaglutide"); abline(h = coef(cox), lty = 2, col = "red")
dev.off()

## ---- models-cost-figure ----
cost_long <- analytic |>
  select(drug, w, Medical = cost_medical, Pharmacy = cost_pharmacy, Total = cost_total) |>
  tidyr::pivot_longer(Medical:Total, names_to = "component", values_to = "cost")
p_cost <- ggplot(cost_long, aes(x = cost + 1, fill = drug, weight = w)) +
  geom_density(alpha = 0.45, colour = NA) +
  scale_x_log10(labels = scales::dollar) +
  facet_wrap(~ component, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = col_drug, name = NULL) +
  labs(x = "12-month allowed cost + $1 (log scale)", y = "Weighted density",
       title = "Figure 5. Distribution of 12-month costs by drug (IPTW)") +
  theme(legend.position = "bottom")
ggsave(file.path(dir_figures, "fig5_cost_distributions.png"), p_cost, width = 7, height = 7, dpi = 200, bg = "white")
