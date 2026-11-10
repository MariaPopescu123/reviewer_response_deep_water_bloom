# Deep Water Bloom Drivers

[![DOI](https://zenodo.org/badge/992111092.svg)](https://doi.org/10.5281/zenodo.21178076)

## About This Repository

This repository includes all workflows needed to reproduce the analyses and figures for the publication "Ten years of monitoring data and explainable artificial intelligence reveal a persistent deep-water phytoplankton bloom driven by physical and biogeochemical processes in a eutrophic reservoir"

------------------------------------------------------------------------

## Instructions to reproduce figures and analysis

1.  Run `01_DataDownload.R` (loads packages/functions, downloads or reloads input data, and creates `variable_labels` used by downstream scripts).

2.  Run scripts in numerical order within `02_Datawrangling/` to reproduce the data products and figures used in the manuscript.

3.  Run `03_Machine_learning/RF_and_SHAP.R`

4.  (Optional) Run `03_Machine_learning/RF_and_SHAP_with_W.R` to fit the same models with the Wedderburn number added as a predictor (Supporting Information Figure S11).

All outputs are written to the `CSVs/` (data products) and `Figs/` (figures) directories. These directories are created automatically by `01_DataDownload.R` if they do not already exist.

### Where figures are saved

Figures are organized into subfolders of `Figs/` by purpose:

- **`Figs/Main Manuscript/`** — the final, curated figures used in the manuscript (`Figure2.png`–`Figure7.png`). Figure 1 is a conceptual/site figure made outside this repository.
- **`Figs/Supporting Information/`** — the final, curated figures used in the Supporting Information (`Figure S1.png`–`Figure S11.png`, including `Figure S6a.png` and `Figure S6b.png`).
- **All other `Figs/` subfolders** (e.g. `Phytos_viz/`, `Data_availability/`, `correlations/`, `Thermocline/`, `metdata/`, `MachineLearning/`, `Daily_interp_Casts/`, `Daily_interp_Casts_postinterp/`, `raw_flora_casts/`, `raw_flora_casts_with_DCM/`) — working and diagnostic figures generated along the way. Several of the manuscript and Supporting Information figures are also saved to one of these working folders in addition to the curated `Main Manuscript/` or `Supporting Information/` folder.

The per-script descriptions below list which figures each script produces and where they are written.

###  Notes

- The workflow requires scripts to run in order in the same R session.
- `02_Datawrangling/02_Phytos_dataframe.R` creates `frame_dates.csv` and `final_phytos.csv`, which are required by later scripts.
- `02_Datawrangling/04_photic_temp_thermo.R` creates `temp_depths_interp` in memory, which is used by `05_buoyancy_freq.R` and `07_schmidt_stability.R`.
- If you run scripts independently (instead of sequentially), some objects must be loaded manually first.
- `00_run_all.R` can be used to source the data-wrangling scripts in order after running `01_DataDownload.R`.

------------------------------------------------------------------------

## Repository Structure

### `01_DataDownload.R`

Scripts and helper functions used to download the raw datasets required for this project. Also creates the output directory tree (`CSVs/`, `Figs/`, `Figs/Main Manuscript/`, `Figs/Supporting Information/`).

*Figures:* none (other scripts populate the figure folders).

### `02_Datawrangling/`

This folder contains a numbered sequence of scripts that build the core analysis datasets and manuscript figures, plus a `00_run_all.R` driver. The scripts are described below.

#### `00_run_all.R`

Sources and runs the numbered DataWrangling scripts (`01`–`11`) in order.

#### `01_water_level.R`

Downloads Beaverdam Reservoir water-level data (2014–2024) from EDI, merges pressure-sensor and historical water level data sources, interpolates the data, and aggregates the time series to weekly water levels.\
Generates a time-series plot colored by year, saves a cleaned CSV, and computes summary statistics on within- and across-year variability (including pre- vs. post-2022 comparisons).

*Figures:* the water-level time-series plot is created for a check but not saved.

*Data:* `CSVs/water_level.csv`.

#### `02_Phytos_dataframe.R`

Cleans and filters FluoroProbe phytoplankton depth profiles (casts), removes questionable casts, and computes deep chlorophyll maximum (DCM) metrics (peak depth and peak concentration) for each cast and week.\
Produces QC plots, annual boxplots and summaries, pairwise year-to-year significance tests, and exports weekly-aggregated DCM depth and magnitude datasets for downstream analyses (e.g., random forest modeling).

*Figures:*
- **Manuscript Figure 4** (paneled DCM depth/magnitude boxplots) → `Figs/Main Manuscript/Figure4.png` (also `Figs/Phytos_viz/boxplots_paneled.png`).
- **Supporting Information Figure S4** (FluoroProbe data availability) → `Figs/Supporting Information/Figure S4.png`.
- **Supporting Information Figure S7** (phytoplankton summary) → `Figs/Supporting Information/Figure S7.png` (also `Figs/Phytos_viz/phytoplankton_summary.png`).
- **Supporting Information Figure S8** (Kruskal–Wallis year comparisons) → `Figs/Supporting Information/Figure S8.png` (also `Figs/Phytos_viz/kruskal-wallis.png`).
- Working/QC figures: group composition plots → `Figs/Phytos_viz/` (`comp.png`, `comp_at_DCM.png`); per-year raw casts → `Figs/raw_flora_casts/`; per-year casts with DCM marked → `Figs/raw_flora_casts_with_DCM/`; total-phytos availability → `Figs/Data_availability/`.

*Data:* `CSVs/phytos.csv`, `CSVs/frame_dates.csv`, `CSVs/final_phytos.csv`.

#### `03_Phytos_heatmaps_profiles.R`

Generates depth–time heatmaps of phytoplankton concentration for Beaverdam Reservoir (2015–2024), masking values below the water level and standardizing color scales across years.\
Identifies the day of peak phytoplankton concentration each year and produces profile plots showing full FluoroProbe casts (by algal group and total) for those maximum-bloom events.

*Figures:*
- **Manuscript Figure 2** (depth–time phytoplankton heatmaps) → `Figs/Main Manuscript/Figure2.png` (also `Figs/Phytos_viz/final_phytos_heatmap_plot.png`).
- **Manuscript Figure 3** (total-phytoplankton profiles for each year's maximum-bloom cast) → `Figs/Main Manuscript/Figure3.png` (also `Figs/Phytos_viz/FP_casts_2025_just_totals.png`).
- **Supporting Information Figure S3** (same maximum-bloom casts, all spectral groups) → `Figs/Supporting Information/Figure S3.png` (also `Figs/Phytos_viz/FP_casts_2025.png`).

#### `04_photic_temp_thermo.R`

This script calculates weekly photic zone depth, interpolated temperature profiles, and thermocline depth for Beaverdam Reservoir (Site 50). It cleans and merges CTD and YSI data, estimates light availability from Secchi depth data, and computes thermocline depth from temperature–depth profiles. The final output combines photic zone, thermocline, and water level observations into a single dataset for use in downstream analyses.

*Figures:* working/diagnostic only — per-year raw temperature casts → `Figs/Daily_interp_Casts/`; the same casts after interpolation → `Figs/Daily_interp_Casts_postinterp/`; per-year casts with the thermocline marked → `Figs/Thermocline/`.

*Data:* `CSVs/temp_at_DCM.csv`, `CSVs/final_photic_thermo.csv`.

#### `05_buoyancy_freq.R`

This script calculates buoyancy frequency (stratification strength) from temperature-depth profiles and extracts the value at the depth of the deep chlorophyll maximum (DCM) each week. The final output is a weekly time series of buoyancy frequency at the DCM for use in analyses of physical controls on phytoplankton structure.

*Figures:* none.

*Data:* `CSVs/final_buoyancy.csv`.

#### `06_nutrients.R`

This script processes nutrient and metal chemistry data for Beaverdam Reservoir, including filtering and flag handling, and interpolating concentrations at the deep chlorophyll maximum (DCM). The final output provides weekly aggregated values of key nutrients (SRP, NH₄) and soluble iron (SFe) for downstream analyses.

*Figures:* none.

*Data:* `CSVs/final_chem.csv`, `CSVs/final_metals.csv`.

#### `07_schmidt_stability.R`

This script calculates Schmidt stability for Beaverdam Reservoir by combining temperature profiles with bathymetry adjusted for water level. It produces a weekly time series of Schmidt stability, which quantifies the energy required to mix the water column, reflecting stratification strength over time.

*Figures:* none.

*Data:* `CSVs/final_schmidt.csv`.

#### `08_NLDAS_downscaling.R`

This script merges EDI and NLDAS meteorological datasets for Beaverdam Reservoir by first computing weekly averages, performing quality control, and downscaling NLDAS to match EDI values using linear regressions. It then combines the datasets, creates lagged variables, visualizes all years of data, and exports a clean weekly meteorological dataset ready for downstream analyses.

*Figures:* working/diagnostic only — combined all-years meteorological plot → `Figs/metdata/NLDAS.png`.

*Data:* `CSVs/EDImet0.csv`, `CSVs/full_met.csv`, `CSVs/final_metdata.csv`.

#### `09_join_all_frames.R`

This code joins all the previously processed weekly datasets — phytoplankton, photic/thermal profiles, buoyancy, nutrient and metals chemistry, Schmidt stability, and meteorology — into a single full_weekly_data dataframe. It then cleans and renames key variables, organizes lagged meteorological variables, filters the time series to be just  2015–2024, and exports the complete weekly dataset. Finally, it calculates summary statistics for high phytoplankton concentrations (max_conc \> 20), including the median, standard deviation, ±1 SD, and sample size, both for concentration and DCM depth.

*Figures:* none.

*Data:* `CSVs/full_data.csv`.

#### `10_Choosing_variables_correlation_matrix.R`

This code creates correlation heatmaps for different groups of weekly variables from full_weekly_data. It also creates the pretty labels used for the remaining figures.

*Figures:*
- **Supporting Information Figure S5** (full correlation matrix) → `Figs/Supporting Information/Figure S5.png` (also `Figs/correlations/full_corr_Matrix.png`).
- Working figures: thermal variable pairing table → `Figs/correlations/thermal_pairing_table.png`.

#### `11_Visualize_final_chosen_variables.R`

This code produces a seasonal overview of the chosen environmental and depth-related variables with a custom DOY window (133-285, roughly May-October).

*Figures:*
- **Supporting Information Figure S1** (yearly summary statistics for each variable) → `Figs/Supporting Information/Figure S1.png` (also `Figs/all_variables_yearly_stats.png`).
- **Supporting Information Figure S2** (seasonal time series of all chosen variables) → `Figs/Supporting Information/Figure S2.png` (also `Figs/all_variables_visualized.png`).

*Data:* `CSVs/summary_statistics_overall.csv`, `CSVs/yearly_variable_stats.csv`.

### `03_Machine_learning/`

This folder contains the scripts for running the random forest models with Shapley Additive Explanations (SHAP).

#### `RF_and_SHAP.R`

This code uses random forest models to predict two metrics of phytoplankton vertical structure (DCM_depth and max_conc) from environmental variables, then applies SHAP values to quantify each predictor’s contribution to the model. It runs separate analyses for depth and magnitude, including weather lags and water column metrics, and generates plots of variable importance, model robustness (jackknife), and SHAP interactions. The results help identify which physical, chemical, and meteorological factors most strongly influence phytoplankton dynamics.

*Figures:*
- **Manuscript Figure 5** (paneled variable importance and SHAP distributions for the depth and magnitude models) → `Figs/Main Manuscript/Figure5.png` (also `Figs/MachineLearning/Fig5_FinalCombined_Depth_Magnitude_RF.png`).
- **Manuscript Figure 6** (SHAP-vs-value interaction panels for the top six DCM depth predictors) → `Figs/Main Manuscript/Figure6.png` (individual panels in `Figs/MachineLearning/SHAP_interaction/Depth/`).
- **Manuscript Figure 7** (SHAP-vs-value interaction panels for the top six DCM magnitude predictors) → `Figs/Main Manuscript/Figure7.png` (individual panels in `Figs/MachineLearning/SHAP_interaction/Magnitude/`).
- **Supporting Information Figure S6a/S6b** (jackknife robustness heatmaps for the depth and magnitude models) → `Figs/Supporting Information/Figure S6a.png` and `Figure S6b.png` (also `Figs/MachineLearning/Depth/Jackknife_Heatmap_over20.png` and `Figs/MachineLearning/Magnitude/MagnitudeJackknife_Heatmap.png`).
- **Supporting Information Figure S9** (SHAP-vs-value panels for *all* depth predictors) → `Figs/Supporting Information/Figure S9.png`.
- **Supporting Information Figure S10** (SHAP-vs-value panels for *all* magnitude predictors) → `Figs/Supporting Information/Figure S10.png`.

#### `RF_and_SHAP_with_W.R`

The same random forest + SHAP models as `RF_and_SHAP.R` (same responses, data filtering, and tuning), but run with the log10 Wedderburn number (`log_wedderburn`) added as a predictor to both the DCM depth and DCM magnitude models. Run it after `RF_and_SHAP.R` in the same R session. All of its outputs and in-memory objects have `_with_W`/`_W` names, so it does not overwrite anything produced by `RF_and_SHAP.R` or any other script.

*Figures:*
- **Supporting Information Figure S11** (with-Wedderburn version of manuscript Figure 5: paneled variable importance and SHAP distributions for the depth and magnitude models) → `Figs/Supporting Information/Figure S11.png` (also `Figs/MachineLearning/FigS11_FinalCombined_Depth_Magnitude_RF_with_W.png`).
- Working figures: with-Wedderburn jackknife robustness heatmaps → `Figs/with_W/Jackknife_Depth_with_W.png` and `Figs/with_W/Jackknife_Magnitude_with_W.png` (also `Figs/MachineLearning/Depth_with_W/` and `Figs/MachineLearning/Magnitude_with_W/`).

### `Functions/`

Reusable functions that support data processing and figure creation. These functions are sourced in `01_DataDownload.R` and then used throughout the pipeline scripts. Descriptions of each are provided here.

#### `data_availability_function.R`

This function is for QAQC purposes and was developed so anyone can see the data availability of any monitoring variable within any dataframe (not to produce publication-ready figures!). It produces a figure that displays which days within each year that we have available observations.

#### `date_sum_variables.R`

Summarizes one or more water-quality variables by Date from a depth profile dataset (typically the daily-interpolated output of `interpolate_variable()`). Returns max/min values, depths of those extremes, and the value at the DCM for each Date. Used by `06_nutrients.R` to build the chemistry and metals summaries that feed the joined RF dataset.

#### `final_data_availability_plot.R`

This function produces the final FluoroProbe Data Availability plot for the Supporting Information.

#### `find_depths.R`

Reads BVR platform sensor data (pressure transducer + thermistor string) together with a depth-offset table and assigns a calibrated depth to each sensor reading. Used by `04_photic_temp_thermo.R` to derive 2021 sensorstring temperature profiles when CTD/YSI data are not available.

#### `interpolate_variable.R`

This function interpolates missing values for a list of water quality variables across both depth and time in a reservoir. It first summarizes the raw data by date and depth, then linearly interpolates values within observed depth and day-of-year ranges, filling gaps while avoiding extrapolation beyond measured data. The result is a complete daily depth grid for each variable, ready for further analysis or modeling.

#### `jackknife.R`

This function performs a jackknife-style random forest analysis to quantify the importance of each predictor variable (%IncMSE) for a response variable, both separately for each year and pooled across all years. It tunes the random forest parameters per year, runs leave-one-out models to estimate robustness, and then summarizes the results as mean ± SD %IncMSE, which it visualizes as a heatmap with variables on the y-axis and years on the x-axis. The output also includes numeric summaries, full jackknife distributions, overall variable rankings, and metadata about the models.

#### `new_var_importance_shap_plots.R`

This function computes and visualizes variables importance (%IncMSE) and SHAP value distributions for a random forest model on a given dataset, optionally saving combined plots.

#### `plot_shap_vs_value_loop.R`

For each variable in vars_to_plot, this function creates a scatterplot of SHAP values vs predictor values colored by z-scaled predictor values, saves individual plots, and optionally creates a multi-panel figure.

#### `weekly_sum_variables.R`

Weekly (Year + Week) variant of `date_sum_variables.R`: same max/min/depth-at-extreme/value-at-DCM summaries but aggregated to weekly resolution. Not used by the current manuscript pipeline; retained as a utility for weekly-resolution exploration.

------------------------------------------------------------------------

## AI Use Disclosure

Generative artificial intelligence tools (claude-opus-4-8) were used to help debug the code in this repository, and document the R scripts and functions. All AI-assisted code was reviewed, tested, and verified by the authors, who take full responsibility for the correctness of the analyses and the interpretation of the results. No analytical results or conclusions were produced by generative AI.

Note that this is distinct from the machine learning methods that are part of the analysis itself. The random forest models and Shapley Additive Explanations (SHAP) described in `03_Machine_learning/` are the explainable artificial intelligence approach reported in the manuscript, and are documented in the manuscript's methods.
