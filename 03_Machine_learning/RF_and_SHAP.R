#RF and SHAP 
#This script runs Random Forest + SHAP workflows for two response variables: DCM depth and DCM magnitude.
# - DCM_depth (using weeks where max_conc > 20)
# - max_conc (all available phytoplankton weeks)
#
# It creates:
# - variable-importance with SHAP score plots (Fig. 5)
# - jackknife robustness heatmaps (Fig. S6)
# - SHAP-vs-value interaction panels for manuscript + Supporting Information (Fig. 6, Fig. 7, Fig. S9, Fig. S10)
#
# Inputs expected in the workspace from prior scripts:
# - full_data, variable_labels
# - helper functions sourced in 01_DataDownload.R:
#   var_importance_shap_plots(), jackknife_incMSE_heatmap(), plot_shap_vs_value_loop()

required_objects <- c("full_data", "variable_labels")
missing_objects <- required_objects[!vapply(required_objects, exists, logical(1), inherits = TRUE)]
if (length(missing_objects) > 0) {
  stop("Missing required objects for RF_and_SHAP.R: ",
       paste(missing_objects, collapse = ", "),
       ". Run 01_DataDownload.R and 02_Datawrangling/10_join_all_frames.R first.")
}

required_functions <- c("var_importance_shap_plots", "jackknife_incMSE_heatmap", "plot_shap_vs_value_loop")
missing_functions <- required_functions[!vapply(required_functions, exists, logical(1), mode = "function", inherits = TRUE)]
if (length(missing_functions) > 0) {
  stop("Missing required helper functions for RF_and_SHAP.R: ",
       paste(missing_functions, collapse = ", "),
       ". Re-run 01_DataDownload.R to source Functions/*.R.")
}

dirs <- c(
  "Figs/MachineLearning",
  "Figs/MachineLearning/Depth",
  "Figs/MachineLearning/Magnitude",
  "Figs/MachineLearning/SHAP_interaction/Depth",
  "Figs/MachineLearning/SHAP_interaction/Magnitude"
)

for (d in dirs) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

####Final Plots####
#------depth------####
depth_analysis_over20 <- full_data|>
  filter(max_conc>20)|>
  select(
    Date, DCM_depth,
    PZ, thermocline_depth, schmidt_stability, WaterLevel_m,
    depth_NH4_ugL_max,depth_NO3NO2_ugL_max,depth_SRP_ugL_max, depth_SFe_mgL_max,
    air_temp_week_avg, wind_week_avg, precip_week_sum)

finaldepthRF_over20 <- var_importance_shap_plots(
  Xdataframe      = depth_analysis_over20,
  XYear           = 2015,
  XYear2          = 2024,
  whichvars       = "",
  response_var    = "DCM_depth",
  save_dir        = "Depth",
  variable_labels = variable_labels
)

#####Jackknife#####
#this is for viewing to see how robust the model is across years Fig. S6
#### Supporting Information Figure S6a (DCM depth jackknife heatmap) ####
depth_jackknife_over20 <- jackknife_incMSE_heatmap(
  Xdataframe     = depth_analysis_over20,
  year_min       = 2015,
  year_max       = 2024,
  metric = "DCM Depth",
  var_order = finaldepthRF_over20$var_order,
  response_var   = "DCM_depth",
  whichvars_label= "",
  save_path      = here::here("Figs","MachineLearning","Depth","Jackknife_Heatmap_over20.png"),
  variable_labels = variable_labels,
  panel_label = "a"
)
# copy to Corresponding Figure folder
ggsave(here::here("Figs","Supporting Information","Figure S6a.png"),
       plot = depth_jackknife_over20$plot,
       width = 12, height = 8, dpi = 400, bg = "white")

print(depth_jackknife_over20$plot)
print(depth_jackknife_over20$imp_summary)
print(depth_jackknife_over20$plot_df)
print(depth_jackknife_over20$imp_long)
print(depth_jackknife_over20$overall_importance)
print(depth_jackknife_over20$year_stats)

####------magnitude-------####
magnitude_analysis <- full_data|>
  select(Date, max_conc, WaterLevel_m, PZ, schmidt_stability, thermocline_depth, N_at_DCM,
         SFe_mgL_at_DCM,SRP_ugL_at_DCM, NH4_ugL_at_DCM, NO3NO2_ugL_at_DCM,
         air_temp_week_avg, wind_week_avg, precip_week_sum)

finalmagnitudeRF <- var_importance_shap_plots(
  Xdataframe      = magnitude_analysis,
  XYear           = 2015,
  XYear2          = 2024,
  whichvars       = "",
  response_var    = "max_conc",
  save_dir        = "Magnitude",
  variable_labels = variable_labels
)


#### Supporting Information Figure S6b (DCM magnitude jackknife heatmap) ####
magnitude_jackknife <- jackknife_incMSE_heatmap(
  Xdataframe     = magnitude_analysis,
  year_min       = 2015,
  year_max       = 2024,
  metric = "DCM Magnitude",
  var_order = finalmagnitudeRF$var_order,
  response_var   = "max_conc",
  whichvars_label= "",
  save_path      = here::here("Figs","MachineLearning","Magnitude","MagnitudeJackknife_Heatmap.png"),
  variable_labels = variable_labels,
  panel_label = "b"
)
# copy to Corresponding Figure folder
ggsave(here::here("Figs","Supporting Information","Figure S6b.png"),
       plot = magnitude_jackknife$plot,
       width = 12, height = 8, dpi = 400, bg = "white")
#if you want to view
#res$plot
#res$summary %>% as.data.frame() %>% head()

tag_theme <- theme(
  plot.tag = element_text(size = 10, face = "bold"),
  plot.tag.position = c(0.05, .98)
)

other_theme <- theme(
  plot.tag = element_text(size = 10, face = "bold"),
  plot.tag.position = c(0.05, .98)
)

p1 <- finaldepthRF_over20$plots$importance + labs(tag = "a") + tag_theme
p2 <- finaldepthRF_over20$plots$shap + labs(tag = "b") + other_theme
p3 <- finalmagnitudeRF$plots$importance + labs(tag = "c") + tag_theme
p4 <- finalmagnitudeRF$plots$shap + labs(tag = "d") + other_theme

make_rf_caption <- function(label, md) {
  sprintf("%s: OOB R² = %.2f | OOB RMSE = %.2f | n = %d | ntree = %d | mtry = %d | nodesize = %d",
          label, md$oob_r2, md$oob_rmse, md$n,
          md$best_params$ntree, md$best_params$mtry, md$best_params$nodesize)
}
fig5_caption <- paste(
  make_rf_caption("Depth model",     finaldepthRF_over20$model_details),
  make_rf_caption("Magnitude model", finalmagnitudeRF$model_details),
  sep = "\n"
)

combined_RF_panels <- (p1 + p2) / (p3 + p4) +
  plot_annotation(
    caption = fig5_caption,
    theme = theme(plot.caption = element_text(size = 10, hjust = 0, lineheight = 1.1))
  )

#### Main Manuscript Figure 5 ####
ggsave(
  filename = here::here("Figs", "MachineLearning", "Fig5_FinalCombined_Depth_Magnitude_RF.png"),
  plot = combined_RF_panels,
  width = 9, height = 5, dpi = 900, bg = "white"
)
# copy to Corresponding Figure folder
ggsave(
  filename = here::here("Figs", "Main Manuscript", "Figure5.png"),
  plot = combined_RF_panels,
  width = 9, height = 5, dpi = 900, bg = "white"
)

print(magnitude_jackknife$plot)
print(magnitude_jackknife$imp_summary)
print(magnitude_jackknife$plot_df)
print(magnitude_jackknife$imp_long)
print(magnitude_jackknife$overall_importance)
print(magnitude_jackknife$year_stats)


####model information####
print(finaldepthRF_over20$tuning_scores)
print(finaldepthRF_over20$importance_table) #most helpful
print(finaldepthRF_over20$shap_long)
print(finaldepthRF_over20$shap_long_filtered)
print(finaldepthRF_over20$model_details) #this too
print(finaldepthRF_over20$counts)




print(finalmagnitudeRF$tuning_scores)
print(finalmagnitudeRF$importance_table) #most helpful
print(finalmagnitudeRF$shap_long)
print(finalmagnitudeRF$shap_long_filtered)
print(finalmagnitudeRF$model_details)
print(finalmagnitudeRF$counts)

#to see the number of observations that are used to calculate OOB
cat("Depth OOB R2 observations:", finaldepthRF_over20$model_details$n, "\n")
cat("Magnitude OOB R2 observations:", finalmagnitudeRF$model_details$n, "\n")


####-----interaction plots for SHAP vs value----####

####----depth####
#for main manuscript figure 6----
#### Main Manuscript Figure 6 ####
depthshap <- finaldepthRF_over20$shap_long
vars_to_plot <- head(finaldepthRF_over20$var_order, 6)


fig6 <- plot_shap_vs_value_loop(
  shap_df = depthshap,
  vars_to_plot = vars_to_plot,
  out_dir = here::here("Figs/MachineLearning/SHAP_interaction/Depth"),
  prefix = "depth",
  analysis_label = "Predictor Effects on DCM Depth Prediction",
  var_labels = variable_labels,
  panel_ncol = 3,
  panel_width = 9,
  panel_height = 5
)
# copy to Corresponding Figure folder
ggsave(here::here("Figs","Main Manuscript","Figure6.png"),
       plot = fig6$panel_plot,
       width = 9, height = 5, dpi = 1200, bg = "white")

#for Supporting Information figure (all variables) S9----
#### Supporting Information Figure S9 ####
vars_to_plot <- finaldepthRF_over20$var_order

figS9 <- plot_shap_vs_value_loop(
  shap_df = depthshap,
  vars_to_plot = vars_to_plot,
  out_dir = here::here("Figs/MachineLearning/SHAP_interaction/Depth"),
  prefix = "SIdepth",
  analysis_label = "Predictor Effects on DCM Depth Prediction",
  panel_ncol = 4,
  var_labels = variable_labels,
  # Save near print size so native font size ~= on-page size; text_scale lifts
  # the smallest fonts to ~9 pt so they render >= 8 pt in the manuscript.
  # Larger canvas gives each panel more room so the titles don't overlap.
  panel_width = 13,
  panel_height = 7,
  text_scale = 1.15
)
# copy to Corresponding Figure folder
ggsave(here::here("Figs","Supporting Information","Figure S9.png"),
       plot = figS9$panel_plot,
       width = 13, height = 7, dpi = 1200, bg = "white")


#----magnitude----
#for main manuscript figure 7----
#### Main Manuscript Figure 7 ####
magnitudeshap <- finalmagnitudeRF$shap_long
vars_to_plot <- head(finalmagnitudeRF$var_order, 6)

fig7 <- plot_shap_vs_value_loop(
  shap_df = magnitudeshap,
  vars_to_plot = vars_to_plot,
  out_dir = here::here("Figs/MachineLearning/SHAP_interaction/Magnitude"),
  prefix = "magnitude",
  analysis_label = "Predictor Effects on DCM Magnitude Prediction",
  var_labels = variable_labels,
  panel_ncol = 3,
  panel_width = 9,
  panel_height = 5
)
# copy to Corresponding Figure folder
ggsave(here::here("Figs","Main Manuscript","Figure7.png"),
       plot = fig7$panel_plot,
       width = 9, height = 5, dpi = 1200, bg = "white")

#for all variables figure S10----
#### Supporting Information Figure S10 ####
magnitudeshap <- finalmagnitudeRF$shap_long
vars_to_plot <- finalmagnitudeRF$var_order


figS10 <- plot_shap_vs_value_loop(
  shap_df = magnitudeshap,
  vars_to_plot = vars_to_plot,
  out_dir = here::here("Figs/MachineLearning/SHAP_interaction/Magnitude"),
  prefix = "SImagnitude",
  analysis_label = "Predictor Effects on DCM Magnitude Prediction",
  var_labels = variable_labels,
  panel_ncol = 4,
  panel_width = 13,
  panel_height = 7,
  text_scale = 1.15
)
# copy to Supporting Information folder
ggsave(here::here("Figs","Supporting Information","Figure S10.png"),
       plot = figS10$panel_plot,
       width = 13, height = 7, dpi = 1200, bg = "white")



#added Rohit's section here####
#Rebuild the published forest exactly (same cleaning, set.seed(123) and grid order as var_importance_shap_plots()); stop if it differs from the forest behind Fig. 5
rebuild_forest <- function(Xdataframe, response_var, published) {
  d <- Xdataframe |> mutate(Year = year(as.Date(Date))) |> filter(Year >= 2015, Year <= 2024) |>
    select(-Date, -Year) |> mutate(across(everything(), ~ ifelse(is.infinite(.x) | is.nan(.x), NA, .x)))
  d <- d[, colMeans(is.na(d)) <= 0.25 | names(d) == response_var, drop = FALSE] |> drop_na()
  f <- as.formula(paste(response_var, "~ ."))
  grid <- expand.grid(mtry = seq_len(max(1, floor((ncol(d) - 1) / 2))), nodesize = c(2, 4, 6, 8),
                      ntree = c(100, 200, 300, 500))
  set.seed(123)
  oob <- t(sapply(seq_len(nrow(grid)), function(i) {
    fit <- randomForest(f, data = d, ntree = grid$ntree[i], mtry = grid$mtry[i],
                        nodesize = grid$nodesize[i], importance = TRUE)
    c(r2 = tail(fit$rsq, 1), mse = tail(fit$mse, 1))
  }))
  b <- grid[order(-oob[, "r2"], oob[, "mse"])[1], ]
  fit <- randomForest(f, data = d, ntree = b$ntree, mtry = b$mtry, nodesize = b$nodesize, importance = TRUE)
  imp <- randomForest::importance(fit, type = 1)[published$importance_table$Variable, 1]
  if (!isTRUE(all.equal(unname(imp), published$importance_table$`%IncMSE`)))
    stop("The rebuilt ", response_var, " forest differs from the published one")
  list(fit = fit, X = d[, names(d) != response_var])
}

# One SHAP run as in the paper (fastshap, adjust = FALSE), with its own seed
shap_run <- function(fit, X, nsim, seed) {
  set.seed(seed)
  s <- fastshap::explain(fit, X = X, nsim = nsim, adjust = FALSE,
                         pred_wrapper = function(object, newdata) predict(object, newdata = newdata))
  as.matrix(as.data.frame(unclass(s)))
}

# 3. Ten runs at each nsim, summarised without any reference run
nsims  <- c(25, 50, 100, 200, 400)   # nsim values compared (same as Rohit's earlier version)
n_runs <- 10                         # SHAP runs per nsim

icc_1 <- function(M) {   # one-way ICC(1,1) of a single run; M = weeks x runs
  k <- ncol(M); msb <- k * var(rowMeans(M)); msw <- sum((M - rowMeans(M))^2) / (nrow(M) * (k - 1))
  (msb - msw) / (msb + (k - 1) * msw)
}
convergence <- function(rb, six, units, model) {
  A <- lapply(nsims, function(ns)   # weeks x predictors x runs, one array per nsim
    simplify2array(lapply(1:n_runs, function(r) shap_run(rb$fit, rb$X, ns, 300000 + ns * 100 + r))))
  sd_runs <- sapply(A, function(a) apply(apply(a, 1:2, sd), 2, median))  # run-to-run SD, median over weeks
  spread  <- sapply(A, function(a) apply(apply(a, 2:3, sd), 1, mean))    # SD across weeks, mean over runs
  pct <- 100 * sd_runs / spread                                         # predictors x nsim
  a100 <- A[[which(nsims == 100)]]; p <- dimnames(a100)[[2]]
  imp  <- apply(abs(a100), 2:3, mean)                                   # mean |SHAP| per predictor and run
  top6 <- apply(imp, 2, function(v) paste(sort(names(sort(v, decreasing = TRUE))[1:6]), collapse = ","))
  per <- data.frame(model, predictor = p, label = unname(variable_labels[p]), in_fig_6_7 = p %in% six,
                    variation_pct = pct[, nsims == 100],
                    icc = sapply(p, function(j) icc_1(a100[, j, ])),
                    min_pairwise_r = sapply(p, function(j) { r <- cor(a100[, j, ]); min(r[upper.tri(r)]) }),
                    cv_mean_abs_shap_pct = 100 * apply(imp, 1, sd) / rowMeans(imp),
                    slope = apply(sd_runs, 1, function(s) unname(coef(lm(log(s) ~ log(nsims)))[2])), row.names = NULL)
  s6 <- per[per$in_fig_6_7, ]; j1 <- six[1]
  list(table = apply(pct[six, , drop = FALSE], 2, function(v) sprintf("%.1f%% (%.1f%%)", median(v), max(v))),
       per = per,
       summary = data.frame(model,
                       variation_median_pct = median(s6$variation_pct), variation_max_pct = max(s6$variation_pct),
                       example_predictor = j1, example_run_to_run_sd = sd_runs[j1, nsims == 100],
                       example_spread_across_weeks = spread[j1, nsims == 100], units,
                       distinct_top6_sets = length(unique(top6)), min_pairwise_r = min(s6$min_pairwise_r),
                       min_icc = min(s6$icc), max_cv_mean_abs_shap_pct = max(s6$cv_mean_abs_shap_pct),
                       slope_median = median(per$slope)))
}

res <- list(
  depth = convergence(rebuild_forest(depth_analysis_over20, "DCM_depth", finaldepthRF_over20),
                      head(finaldepthRF_over20$var_order, 6), "m", "DCM depth"),
  magnitude = convergence(rebuild_forest(magnitude_analysis, "max_conc", finalmagnitudeRF),
                          head(finalmagnitudeRF$var_order, 6), "ug/L", "DCM magnitude"))

# 4. Outputs
out <- "Figs/Reviewer_C7"; dir.create(out, recursive = TRUE, showWarnings = FALSE)
table_r1 <- data.frame(nsim = nsims, relative_computing_time = paste0(nsims / 100, "x"),
                       DCM_depth_median_max = res$depth$table, DCM_magnitude_median_max = res$magnitude$table)
summary_100 <- rbind(res$depth$summary, res$magnitude$summary)
per_predictor <- rbind(res$depth$per, res$magnitude$per)
write.csv(table_r1, file.path(out, "Table_R1.csv"), row.names = FALSE)
write.csv(summary_100, file.path(out, "nsim100_summary.csv"), row.names = FALSE)
write.csv(per_predictor, file.path(out, "per_predictor_nsim100.csv"), row.names = FALSE)
print(table_r1, row.names = FALSE)
print(t(summary_100))

#### Supporting Information Table S2 (SHAP Monte Carlo convergence; Table R1 as a figure) ####
s2_body <- data.frame(
  nsim = as.character(table_r1$nsim),
  time = sub("x$", "×", table_r1$relative_computing_time),
  depth = table_r1$DCM_depth_median_max,
  magnitude = table_r1$DCM_magnitude_median_max,
  stringsAsFactors = FALSE
)
colnames(s2_body) <- c("Monte Carlo\nsimulations (nsim)", "Relative\ncomputing time",
                       "DCM depth\nmodel", "DCM magnitude\nmodel")

s2_row100 <- which(table_r1$nsim == 100)   # nsim used in the paper: bold + shaded
s2_theme <- gridExtra::ttheme_minimal(
  core = list(fg_params = list(fontsize = 10, hjust = 0.5, x = 0.5,
                               fontface = ifelse(seq_len(nrow(s2_body)) == s2_row100, "bold", "plain")),
              bg_params = list(fill = ifelse(seq_len(nrow(s2_body)) == s2_row100, "grey92", "white"), col = NA),
              padding = unit(c(4, 3.2), "mm")),
  colhead = list(fg_params = list(fontsize = 10, fontface = "bold", hjust = 0.5, x = 0.5),
                 padding = unit(c(4, 3.2), "mm"))
)
s2_tbl <- gridExtra::tableGrob(s2_body, rows = NULL, theme = s2_theme)
s2_W <- 7                                             # table width (in), equal columns
s2_tbl$widths <- unit(rep(s2_W / 4, 4), "in")

# Spanning header over the two model columns, then booktabs-style rules
s2_tbl <- gtable::gtable_add_rows(s2_tbl, unit(11, "mm"), pos = 0)
s2_tbl <- gtable::gtable_add_grob(
  s2_tbl, grid::textGrob("Run-to-run variation in SHAP values\nmedian (maximum)",
                         gp = grid::gpar(fontsize = 10, fontface = "bold", lineheight = 1.1)),
  t = 1, l = 3, r = 4, clip = "off")
s2_rule <- function(y, lwd) grid::segmentsGrob(0, y, 1, y, gp = grid::gpar(lwd = lwd))
s2_tbl <- gtable::gtable_add_grob(s2_tbl, s2_rule(1, 2),   t = 1, l = 1, r = ncol(s2_tbl), name = "top_rule")
s2_tbl <- gtable::gtable_add_grob(s2_tbl, grid::segmentsGrob(0.03, 0, 0.97, 0, gp = grid::gpar(lwd = 0.8)),
                                  t = 1, l = 3, r = 4, name = "span_rule")
s2_tbl <- gtable::gtable_add_grob(s2_tbl, s2_rule(0, 1.2), t = 2, l = 1, r = ncol(s2_tbl), name = "head_rule")
s2_tbl <- gtable::gtable_add_grob(s2_tbl, s2_rule(0, 2),   t = nrow(s2_tbl), l = 1, r = ncol(s2_tbl), name = "bottom_rule")

s2_H <- grid::convertHeight(sum(s2_tbl$heights), "in", valueOnly = TRUE)

dir.create("Figs/Supporting Information", recursive = TRUE, showWarnings = FALSE)
ggsave("Figs/Supporting Information/Table S2.png",
       plot = gridExtra::arrangeGrob(s2_tbl, vp = grid::viewport(width = 0.94, height = 0.9)),
       device = ragg::agg_png, width = s2_W / 0.94, height = s2_H / 0.9, units = "in", dpi = 600, bg = "white")

