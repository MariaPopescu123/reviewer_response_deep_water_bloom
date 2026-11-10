#RF and SHAP, with log10 Wedderburn Number as a predictor
#Same models as RF_and_SHAP.R, but run with log_wedderburn added as a predictor in both models.
#Every output has a *_with_W name or folder, so nothing here overwrites the outputs of RF_and_SHAP.R
#or any other script.
#This script runs Random Forest + SHAP workflows for two response variables: DCM depth and DCM magnitude.
# - DCM_depth (using weeks where max_conc > 20)
# - max_conc (all available phytoplankton weeks)
#
# It creates:
# - variable-importance with SHAP score plots (Supporting Information Fig. S11; the with-Wedderburn
#   version of manuscript Fig. 5)
# - jackknife robustness heatmaps (with-Wedderburn versions of Fig. S6; working figures only)
#
# Inputs expected in the workspace from prior scripts:
# - full_data, variable_labels
# - helper functions sourced in 01_DataDownload.R:
#   var_importance_shap_plots(), jackknife_incMSE_heatmap(), plot_shap_vs_value_loop()

required_objects_W <- c("full_data", "variable_labels")
missing_objects_W <- required_objects_W[!vapply(required_objects_W, exists, logical(1), inherits = TRUE)]
if (length(missing_objects_W) > 0) {
  stop("Missing required objects for RF_and_SHAP_with_W.R: ",
       paste(missing_objects_W, collapse = ", "),
       ". Run 01_DataDownload.R and 02_Datawrangling/10_join_all_frames.R first.")
}

required_functions_W <- c("var_importance_shap_plots", "jackknife_incMSE_heatmap", "plot_shap_vs_value_loop")
missing_functions_W <- required_functions_W[!vapply(required_functions_W, exists, logical(1), mode = "function", inherits = TRUE)]
if (length(missing_functions_W) > 0) {
  stop("Missing required helper functions for RF_and_SHAP_with_W.R: ",
       paste(missing_functions_W, collapse = ", "),
       ". Re-run 01_DataDownload.R to source Functions/*.R.")
}

dirs_W <- c(
  "Figs/MachineLearning",
  "Figs/MachineLearning/Depth_with_W",
  "Figs/MachineLearning/Magnitude_with_W",
  "Figs/MachineLearning/SHAP_interaction/Depth_with_W",
  "Figs/MachineLearning/SHAP_interaction/Magnitude_with_W",
  "Figs/with_W",
  "Figs/Supporting Information"
)

for (d_W in dirs_W) {
  if (!dir.exists(d_W)) dir.create(d_W, recursive = TRUE)
}

####Final Plots####
#------depth------####
depth_analysis_over20_W <- full_data|>
  filter(max_conc>20)|>
  select(
    Date, DCM_depth,
    PZ, thermocline_depth, schmidt_stability, log_wedderburn, WaterLevel_m,
    depth_NH4_ugL_max,depth_NO3NO2_ugL_max,depth_SRP_ugL_max, depth_SFe_mgL_max,
    air_temp_week_avg, wind_week_avg, precip_week_sum)

finaldepthRF_over20_W <- var_importance_shap_plots(
  Xdataframe      = depth_analysis_over20_W,
  XYear           = 2015,
  XYear2          = 2024,
  whichvars       = "",
  response_var    = "DCM_depth",
  save_dir        = "Depth_with_W",
  variable_labels = variable_labels
)

#####Jackknife#####
#this is for viewing to see how robust the model is across years (with-Wedderburn version of Fig. S6a)
#### DCM depth jackknife heatmap, with Wedderburn (working figure) ####
depth_jackknife_over20_W <- jackknife_incMSE_heatmap(
  Xdataframe     = depth_analysis_over20_W,
  year_min       = 2015,
  year_max       = 2024,
  metric = "DCM Depth",
  var_order = finaldepthRF_over20_W$var_order,
  response_var   = "DCM_depth",
  whichvars_label= "",
  save_path      = here::here("Figs","MachineLearning","Depth_with_W","Jackknife_Heatmap_over20.png"),
  variable_labels = variable_labels,
  panel_label = "a"
)
# copy to the with_W folder
ggsave(here::here("Figs","with_W","Jackknife_Depth_with_W.png"),
       plot = depth_jackknife_over20_W$plot,
       width = 12, height = 8, dpi = 400, bg = "white")

print(depth_jackknife_over20_W$plot)
print(depth_jackknife_over20_W$imp_summary)
print(depth_jackknife_over20_W$plot_df)
print(depth_jackknife_over20_W$imp_long)
print(depth_jackknife_over20_W$overall_importance)
print(depth_jackknife_over20_W$year_stats)

####------magnitude-------####
magnitude_analysis_W <- full_data|>
  select(Date, max_conc, WaterLevel_m, PZ, schmidt_stability, log_wedderburn, thermocline_depth, N_at_DCM,
         SFe_mgL_at_DCM,SRP_ugL_at_DCM, NH4_ugL_at_DCM, NO3NO2_ugL_at_DCM,
         air_temp_week_avg, wind_week_avg, precip_week_sum)

finalmagnitudeRF_W <- var_importance_shap_plots(
  Xdataframe      = magnitude_analysis_W,
  XYear           = 2015,
  XYear2          = 2024,
  whichvars       = "",
  response_var    = "max_conc",
  save_dir        = "Magnitude_with_W",
  variable_labels = variable_labels
)


#### DCM magnitude jackknife heatmap, with Wedderburn (with-Wedderburn version of Fig. S6b; working figure) ####
magnitude_jackknife_W <- jackknife_incMSE_heatmap(
  Xdataframe     = magnitude_analysis_W,
  year_min       = 2015,
  year_max       = 2024,
  metric = "DCM Magnitude",
  var_order = finalmagnitudeRF_W$var_order,
  response_var   = "max_conc",
  whichvars_label= "",
  save_path      = here::here("Figs","MachineLearning","Magnitude_with_W","MagnitudeJackknife_Heatmap.png"),
  variable_labels = variable_labels,
  panel_label = "b"
)
# copy to the with_W folder
ggsave(here::here("Figs","with_W","Jackknife_Magnitude_with_W.png"),
       plot = magnitude_jackknife_W$plot,
       width = 12, height = 8, dpi = 400, bg = "white")
#if you want to view
#res$plot
#res$summary %>% as.data.frame() %>% head()

tag_theme_W <- theme(
  plot.tag = element_text(size = 10, face = "bold"),
  plot.tag.position = c(0.05, .98)
)

other_theme_W <- theme(
  plot.tag = element_text(size = 10, face = "bold"),
  plot.tag.position = c(0.05, .98)
)

p1_W <- finaldepthRF_over20_W$plots$importance + labs(tag = "a", title = "Depth Variable Importance") + tag_theme_W
p2_W <- finaldepthRF_over20_W$plots$shap + labs(tag = "b", title = "Depth SHAP value distribution") + other_theme_W
p3_W <- finalmagnitudeRF_W$plots$importance + labs(tag = "c", title = "Magnitude Variable Importance") + tag_theme_W
p4_W <- finalmagnitudeRF_W$plots$shap + labs(tag = "d", title = "Magnitude SHAP value distribution") + other_theme_W

make_rf_caption_W <- function(label, md) {
  sprintf("%s: OOB R² = %.2f | OOB RMSE = %.2f | n = %d | ntree = %d | mtry = %d | nodesize = %d",
          label, md$oob_r2, md$oob_rmse, md$n,
          md$best_params$ntree, md$best_params$mtry, md$best_params$nodesize)
}
figS11_caption <- paste(
  make_rf_caption_W("Depth model",     finaldepthRF_over20_W$model_details),
  make_rf_caption_W("Magnitude model", finalmagnitudeRF_W$model_details),
  sep = "\n"
)

combined_RF_panels_W <- (p1_W + p2_W) / (p3_W + p4_W) +
  plot_annotation(
    caption = figS11_caption,
    theme = theme(plot.caption = element_text(size = 10, hjust = 0, lineheight = 1.1))
  )

#### Supporting Information Figure S11 (with-Wedderburn version of manuscript Figure 5) ####
ggsave(
  filename = here::here("Figs", "MachineLearning", "FigS11_FinalCombined_Depth_Magnitude_RF_with_W.png"),
  plot = combined_RF_panels_W,
  width = 9, height = 5, dpi = 900, bg = "white"
)
# copy to Corresponding Figure folder
ggsave(
  filename = here::here("Figs", "Supporting Information", "Figure S11.png"),
  plot = combined_RF_panels_W,
  width = 9, height = 5, dpi = 900, bg = "white"
)

print(magnitude_jackknife_W$plot)
print(magnitude_jackknife_W$imp_summary)
print(magnitude_jackknife_W$plot_df)
print(magnitude_jackknife_W$imp_long)
print(magnitude_jackknife_W$overall_importance)
print(magnitude_jackknife_W$year_stats)


####model information####
print(finaldepthRF_over20_W$tuning_scores)
print(finaldepthRF_over20_W$importance_table) #most helpful
print(finaldepthRF_over20_W$shap_long)
print(finaldepthRF_over20_W$shap_long_filtered)
print(finaldepthRF_over20_W$model_details) #this too
print(finaldepthRF_over20_W$counts)




print(finalmagnitudeRF_W$tuning_scores)
print(finalmagnitudeRF_W$importance_table) #most helpful
print(finalmagnitudeRF_W$shap_long)
print(finalmagnitudeRF_W$shap_long_filtered)
print(finalmagnitudeRF_W$model_details)
print(finalmagnitudeRF_W$counts)

#to see the number of observations that are used to calculate OOB
cat("Depth OOB R2 observations:", finaldepthRF_over20_W$model_details$n, "\n")
cat("Magnitude OOB R2 observations:", finalmagnitudeRF_W$model_details$n, "\n")

