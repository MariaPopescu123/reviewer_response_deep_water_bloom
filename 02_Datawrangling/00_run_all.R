# Run all data wrangling scripts in order
# See README for information on what each script produces

source("02_Datawrangling/01_water_level.R")
source("02_Datawrangling/02_Phytos_dataframe.R")
# After running 02_Phytos_dataframe.R, the following is just an aesthetic warning and can be ignored:
# `geom_path()`: Each group consists of only one observation.
# ℹ Do you need to adjust the group aesthetic?


source("02_Datawrangling/03_Phytos_heatmaps_profiles.R")
source("02_Datawrangling/04_photic_temp_thermo.R")
source("02_Datawrangling/05_buoyancy_freq.R")
source("02_Datawrangling/06_nutrients.R")
source("02_Datawrangling/07_schmidt_stability.R")
source("02_Datawrangling/08_NLDAS_downscaling.R")
source("02_Datawrangling/09_join_all_frames.R")
source("02_Datawrangling/10_Choosing_variables_correlation_matrix.R")
source("02_Datawrangling/11_Visualize_final_chosen_variables.R")
