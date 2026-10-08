# =============================================================================
# 00b_dag.R
# Purpose: encode the causal assumptions (DAG) and derive the minimal adjustment set
#          for the effect of tirzepatide vs semaglutide 2.4 mg on persistence and costs
# Output:  06_output/figures/fig0_dag_persistence.png, fig0_dag_costs.png,
#          06_output/tables/dag_adjustment_sets.txt
# =============================================================================
source(here::here("05_code", "00_setup.R"))

## ---- dag-define ----
# Nodes measured in claims are written in CamelCase; unmeasured nodes end in "_U".
dag_persist <- dagitty::dagitty('dag {
  Drug [exposure]
  Persistence [outcome]
  Age -> {Drug Persistence ObesitySeverity Comorbidity BaselineUse}
  Sex -> {Drug Persistence Comorbidity}
  Region -> {Drug Persistence PlanType}
  PlanType -> {Drug Persistence OOPCost}
  CalendarTime -> {Drug Persistence}
  ObesitySeverity -> {Drug Persistence Comorbidity}
  Comorbidity -> {Drug Persistence BaselineUse}
  PriorAOM -> {Drug Persistence}
  BaselineUse -> {Drug Persistence}
  Endocrinologist -> {Drug Persistence}
  SES_U -> {PlanType Region Persistence}
  Preference_U -> {Drug}
  Drug -> {GI_AE WeightLoss OOPCost Persistence}
  GI_AE -> Persistence
  WeightLoss -> Persistence
  OOPCost -> Persistence
  Comorbidity -> Endocrinologist
  ObesitySeverity -> PriorAOM
}')

# Cost outcome DAG: persistence becomes a mediator between drug and costs
dag_cost <- dagitty::dagitty('dag {
  Drug [exposure]
  Costs [outcome]
  Age -> {Drug Costs ObesitySeverity Comorbidity BaselineUse}
  Sex -> {Drug Costs Comorbidity}
  Region -> {Drug Costs PlanType}
  PlanType -> {Drug Costs}
  CalendarTime -> {Drug Costs}
  ObesitySeverity -> {Drug Costs Comorbidity}
  Comorbidity -> {Drug Costs BaselineUse}
  PriorAOM -> {Drug Costs}
  BaselineUse -> {Drug Costs}
  Endocrinologist -> {Drug Costs}
  SES_U -> {PlanType Region Costs}
  Preference_U -> {Drug}
  Drug -> {Persistence GI_AE Costs}
  Persistence -> Costs
  GI_AE -> {Persistence Costs}
  Comorbidity -> Endocrinologist
  ObesitySeverity -> PriorAOM
}')

## ---- dag-adjust ----
# Minimal sufficient adjustment sets (unmeasured nodes cannot be used)
latent <- c("SES_U", "Preference_U")
dagitty::latents(dag_persist) <- latent
dagitty::latents(dag_cost)    <- latent
adj_persist <- dagitty::adjustmentSets(dag_persist, type = "minimal")
adj_cost    <- dagitty::adjustmentSets(dag_cost, type = "minimal")
print(adj_persist); print(adj_cost)
cat("Mediators NOT to adjust for (descendants of Drug):",
    paste(setdiff(dagitty::descendants(dag_persist, "Drug"), c("Drug", "Persistence")), collapse = ", "), "\n")
writeLines(c("Persistence DAG - minimal adjustment set(s):", capture.output(print(adj_persist)),
             "", "Cost DAG - minimal adjustment set(s):", capture.output(print(adj_cost))),
           file.path(dir_tables, "dag_adjustment_sets.txt"))

## ---- dag-plot ----
node_role <- function(dag, outcome) {
  tidy <- ggdag::tidy_dagitty(dag, layout = "sugiyama", seed = 3)
  tidy$data <- tidy$data |>
    mutate(role = case_when(
      name == "Drug" ~ "Exposure",
      name == outcome ~ "Outcome",
      grepl("_U$", name) ~ "Unmeasured",
      name %in% c("GI_AE", "WeightLoss", "OOPCost", "Persistence") ~ "Mediator (do not adjust)",
      TRUE ~ "Measured confounder (adjusted)"))
  tidy
}
plot_dag <- function(dag, outcome, title) {
  ggplot(node_role(dag, outcome), aes(x = x, y = y, xend = xend, yend = yend)) +
    ggdag::geom_dag_edges(edge_colour = "grey55", edge_width = 0.35) +
    ggdag::geom_dag_point(aes(colour = role), size = 19) +
    ggdag::geom_dag_text(colour = "black", size = 2.6) +
    scale_colour_manual(values = c("Exposure" = "#7FB3E0", "Outcome" = "#F2B880",
                                   "Unmeasured" = "#D9D9D9", "Mediator (do not adjust)" = "#E6A0A0",
                                   "Measured confounder (adjusted)" = "#A8D5A2"), name = NULL) +
    ggdag::theme_dag() + theme(legend.position = "bottom") +
    guides(colour = guide_legend(nrow = 2)) +
    labs(title = title)
}
p_dag1 <- plot_dag(dag_persist, "Persistence", "DAG 1. Tirzepatide vs semaglutide 2.4 mg and 12-month persistence")
p_dag2 <- plot_dag(dag_cost, "Costs", "DAG 2. Tirzepatide vs semaglutide 2.4 mg and 12-month costs / utilization")
ggsave(file.path(dir_figures, "fig0_dag_persistence.png"), p_dag1, width = 11, height = 7.5, dpi = 200, bg = "white")
ggsave(file.path(dir_figures, "fig0_dag_costs.png"), p_dag2, width = 11, height = 7.5, dpi = 200, bg = "white")
