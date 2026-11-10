#RF and SHAP, with the other DCM response included as a predictor (Reviewer 2)
#Same models as RF_and_SHAP.R (no Wedderburn number), except that:
# - the DCM depth model also uses DCM magnitude (max_conc) as a predictor
# - the DCM magnitude model also uses DCM depth (DCM_depth) as a predictor
#This tests whether either response explains the other once the environmental drivers are included.
#Every output and in-memory object has a *_with_response / _R2 name, so nothing here overwrites
#the outputs of RF_and_SHAP.R, RF_and_SHAP_with_W.R, or any other script.
#
# It creates:
# - variable-importance with SHAP score plots in the same layout as Fig. S11
#   -> Figs/Reviewer 2/reviewer_RF_with_response.png
#
# Inputs expected in the workspace from prior scripts:
# - full_data, variable_labels
# - helper function sourced in 01_DataDownload.R: var_importance_shap_plots()

required_objects_R2 <- c("full_data", "variable_labels")
missing_objects_R2 <- required_objects_R2[!vapply(required_objects_R2, exists, logical(1), inherits = TRUE)]
if (length(missing_objects_R2) > 0) {
  stop("Missing required objects for RF_and_SHAP_with_response.R: ",
       paste(missing_objects_R2, collapse = ", "),
       ". Run 01_DataDownload.R and 02_Datawrangling/10_join_all_frames.R first.")
}
if (!exists("var_importance_shap_plots", mode = "function", inherits = TRUE)) {
  stop("Missing var_importance_shap_plots(). Re-run 01_DataDownload.R to source Functions/*.R.")
}

dirs_R2 <- c(
  "Figs/MachineLearning/Depth_with_response",
  "Figs/MachineLearning/Magnitude_with_response",
  "Figs/Reviewer 2"
)
for (d_R2 in dirs_R2) {
  if (!dir.exists(d_R2)) dir.create(d_R2, recursive = TRUE)
}

#------depth (+ max_conc as a predictor)------####
depth_analysis_over20_R2 <- full_data|>
  filter(max_conc>20)|>
  select(
    Date, DCM_depth,
    max_conc,
    PZ, thermocline_depth, schmidt_stability, WaterLevel_m,
    depth_NH4_ugL_max,depth_NO3NO2_ugL_max,depth_SRP_ugL_max, depth_SFe_mgL_max,
    air_temp_week_avg, wind_week_avg, precip_week_sum)

finaldepthRF_over20_R2 <- var_importance_shap_plots(
  Xdataframe      = depth_analysis_over20_R2,
  XYear           = 2015,
  XYear2          = 2024,
  whichvars       = "",
  response_var    = "DCM_depth",
  save_dir        = "Depth_with_response",
  variable_labels = variable_labels
)

#------magnitude (+ DCM_depth as a predictor)------####
magnitude_analysis_R2 <- full_data|>
  select(Date, max_conc,
         DCM_depth,
         WaterLevel_m, PZ, schmidt_stability, thermocline_depth, N_at_DCM,
         SFe_mgL_at_DCM,SRP_ugL_at_DCM, NH4_ugL_at_DCM, NO3NO2_ugL_at_DCM,
         air_temp_week_avg, wind_week_avg, precip_week_sum)

finalmagnitudeRF_R2 <- var_importance_shap_plots(
  Xdataframe      = magnitude_analysis_R2,
  XYear           = 2015,
  XYear2          = 2024,
  whichvars       = "",
  response_var    = "max_conc",
  save_dir        = "Magnitude_with_response",
  variable_labels = variable_labels
)

#------combined figure (same layout as Fig. S11)------####
tag_theme_R2 <- theme(
  plot.tag = element_text(size = 10, face = "bold"),
  plot.tag.position = c(0.05, .98)
)

p1_R2 <- finaldepthRF_over20_R2$plots$importance + labs(tag = "a", title = "Depth Variable Importance") + tag_theme_R2
p2_R2 <- finaldepthRF_over20_R2$plots$shap + labs(tag = "b", title = "Depth SHAP value distribution") + tag_theme_R2
p3_R2 <- finalmagnitudeRF_R2$plots$importance + labs(tag = "c", title = "Magnitude Variable Importance") + tag_theme_R2
p4_R2 <- finalmagnitudeRF_R2$plots$shap + labs(tag = "d", title = "Magnitude SHAP value distribution") + tag_theme_R2

make_rf_caption_R2 <- function(label, md) {
  sprintf("%s: OOB R² = %.2f | OOB RMSE = %.2f | n = %d | ntree = %d | mtry = %d | nodesize = %d",
          label, md$oob_r2, md$oob_rmse, md$n,
          md$best_params$ntree, md$best_params$mtry, md$best_params$nodesize)
}
reviewer_caption_R2 <- paste(
  make_rf_caption_R2("Depth model (+ DCM magnitude)",     finaldepthRF_over20_R2$model_details),
  make_rf_caption_R2("Magnitude model (+ DCM depth)",     finalmagnitudeRF_R2$model_details),
  sep = "\n"
)

combined_RF_panels_R2 <- (p1_R2 + p2_R2) / (p3_R2 + p4_R2) +
  plot_annotation(
    caption = reviewer_caption_R2,
    theme = theme(plot.caption = element_text(size = 10, hjust = 0, lineheight = 1.1))
  )

#### Reviewer 2 figure: RF with the other response as a predictor ####
ggsave(
  filename = here::here("Figs", "Reviewer 2", "reviewer_RF_with_response.png"),
  plot = combined_RF_panels_R2,
  width = 9, height = 5, dpi = 900, bg = "white"
)

####model information####
print(finaldepthRF_over20_R2$importance_table)
print(finaldepthRF_over20_R2$model_details)
print(finalmagnitudeRF_R2$importance_table)
print(finalmagnitudeRF_R2$model_details)
cat(reviewer_caption_R2, "\n")
