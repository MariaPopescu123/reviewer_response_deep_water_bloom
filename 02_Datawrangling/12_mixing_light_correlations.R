#Maria Popescu

#this script:
# 1. calculates mixed layer depth (MLD) for each phyto-cast Date
# 2. pulls light attenuation (K_d), photic zone depth (PZ), and schmidt stability for the same Dates
# 3. calculates Spearman correlations among MLD, schmidt stability, PZ, and K_d
# 4. makes a correlation heatmap + pairwise scatterplots
#
# MLD: shallowest depth where temperature is >= mld_threshold colder than at 0.5 m
# (the same reference depth as surface_temp). If the column never cools by that much,
# it is mixed to the bottom and MLD = deepest profile depth.
#
# K_d note: K_d = 1.7 / Secchi and PZ = 4.605 / K_d (04_photic_temp_thermo.R), so PZ and
# K_d are near-perfectly inversely correlated by construction. They only diverge where
# PZ is capped at WaterLevel_m.
#
# Inputs:
# - temp_depths_interp, photic_zone_frame (from 04_photic_temp_thermo.R)
# - CSVs/full_data.csv (from 10_join_all_frames.R)
# - variable_labels (from 01_DataDownload.R)
#
# Outputs:
# - CSVs/mixing_light_vars.csv (per-Date values) and CSVs/mixing_light_correlations.csv
# - Figs/correlations/mixing_light_correlations.png

required_objects <- c("temp_depths_interp", "photic_zone_frame", "variable_labels")
missing_objects <- required_objects[!vapply(required_objects, exists, logical(1), inherits = TRUE)]
if (length(missing_objects) > 0) {
  stop("Missing required objects for 12_mixing_light_correlations.R: ",
       paste(missing_objects, collapse = ", "),
       ". Run 01_DataDownload.R and 04_photic_temp_thermo.R first.")
}
if (!file.exists("CSVs/full_data.csv")) {
  stop("Missing CSVs/full_data.csv. Run 10_join_all_frames.R first.")
}

if (!dir.exists("Figs/correlations")) {
  dir.create("Figs/correlations", recursive = TRUE)
}

#temperature drop from 0.5 m that defines the bottom of the mixed layer (degrees C)
mld_threshold <- 1

full_data <- read.csv("CSVs/full_data.csv") |>
  mutate(Date = as.Date(Date))

####Mixed layer depth####
mld_one_day <- function(temp, depth) {
  ref_temp <- temp[which.min(abs(depth - 0.5))]
  below <- which(depth > 0.5 & temp <= ref_temp - mld_threshold)
  if (length(below) == 0) return(max(depth))
  i <- below[1]
  #interpolate between the bins on either side of the threshold crossing
  approx(temp[c(i - 1, i)], depth[c(i - 1, i)], xout = ref_temp - mld_threshold, ties = mean)$y
}

mld_frame <- temp_depths_interp |>
  mutate(Date = as.Date(Date)) |>
  filter(Date %in% full_data$Date, !is.na(Temp_C)) |>
  group_by(Date, Depth_m) |>
  summarise(Temp_C = mean(Temp_C), .groups = "drop") |>
  arrange(Date, Depth_m) |>
  group_by(Date) |>
  summarise(MLD = mld_one_day(Temp_C, Depth_m), .groups = "drop")

####K_d####
kd_frame <- photic_zone_frame |>
  ungroup() |>
  mutate(Date = as.Date(Date)) |>
  select(Date, K_d = sec_K_d)

####Join for phyto-cast Dates####
mixing_light <- full_data |>
  select(Date, schmidt_stability, PZ) |>
  left_join(mld_frame, by = "Date") |>
  left_join(kd_frame,  by = "Date") |>
  select(Date, MLD, schmidt_stability, PZ, K_d)

write.csv(mixing_light, "CSVs/mixing_light_vars.csv", row.names = FALSE)

####Spearman correlations####
vars <- c("MLD", "schmidt_stability", "PZ", "K_d")
pairs <- combn(vars, 2, simplify = FALSE)

cor_table <- map_dfr(pairs, function(p) {
  d <- mixing_light |> select(all_of(p)) |> drop_na()
  test <- suppressWarnings(cor.test(d[[1]], d[[2]], method = "spearman"))
  tibble(Var1 = p[1], Var2 = p[2], rho = unname(test$estimate), p_value = test$p.value, n = nrow(d))
})
print(cor_table)

write.csv(cor_table, "CSVs/mixing_light_correlations.csv", row.names = FALSE)

####Figure####
#fall back to local labels if variable_labels predates MLD / K_d (otherwise both become NA,
#collapse into one factor level, and their tiles draw on top of each other)
fallback_labels <- c(MLD = "Mixed Layer Depth (m)",
                     schmidt_stability = "Schmidt Stability (J/m²)",
                     PZ = "Photic Zone Depth (m)",
                     K_d = "Light Attenuation Coefficient Kd (m⁻¹)")
short_labels <- coalesce(unname(variable_labels[vars]), unname(fallback_labels[vars]))
names(short_labels) <- vars

#a) heatmap, same color scale as the full correlation matrix (Fig. S5)
heat_df <- bind_rows(
  cor_table,
  cor_table |> rename(Var1 = Var2, Var2 = Var1),
  tibble(Var1 = vars, Var2 = vars, rho = NA_real_) #diagonal left blank
) |>
  mutate(Var1 = factor(Var1, levels = vars, labels = short_labels),
         Var2 = factor(Var2, levels = rev(vars), labels = rev(short_labels)))

heat_plot <- ggplot(heat_df, aes(x = Var1, y = Var2, fill = rho)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(data = ~ filter(.x, !is.na(rho)),
            aes(label = sprintf("%.2f", rho), color = abs(rho) > 0.6), size = 3.5) +
  scale_color_manual(values = c(`TRUE` = "white", `FALSE` = "black"), guide = "none") +
  scale_fill_gradient2(low = "red", mid = "white", high = "blue", midpoint = 0,
                       limits = c(-1, 1), na.value = "grey92", name = "Spearman ρ") +
  scale_x_discrete(position = "top", labels = scales::label_wrap(14)) +
  scale_y_discrete(labels = scales::label_wrap(18)) +
  coord_fixed() +
  theme_classic() +
  theme(axis.title = element_blank(), axis.line = element_blank(), axis.ticks = element_blank(),
        axis.text = element_text(size = 9))

#b) pairwise scatterplots with rho annotated
scatter_plots <- map(pairs, function(p) {
  stats <- cor_table |> filter(Var1 == p[1], Var2 == p[2])
  ggplot(mixing_light, aes(x = .data[[p[1]]], y = .data[[p[2]]])) +
    geom_point(size = 1.5, alpha = 0.7, color = "grey25") +
    #rho above the panel so it never sits on top of points
    labs(x = short_labels[p[1]], y = str_wrap(short_labels[p[2]], 22),
         subtitle = sprintf("ρ = %.2f, n = %d", stats$rho, stats$n)) +
    theme_bw() +
    theme(axis.title = element_text(size = 8), axis.text = element_text(size = 7),
          plot.subtitle = element_text(size = 8, hjust = 1, margin = ggplot2::margin(b = 2)),
          panel.grid.minor = element_blank())
})

mixing_light_plot <- (heat_plot | wrap_plots(scatter_plots, ncol = 3)) +
  plot_layout(widths = c(1, 2.2)) +
  plot_annotation(tag_levels = list(c("a", "b", "c", "d", "e", "f", "g"))) &
  theme(plot.tag = element_text(size = 11, face = "bold"))
mixing_light_plot

ggsave("Figs/correlations/mixing_light_correlations.png", plot = mixing_light_plot,
       width = 13, height = 5.5, dpi = 300, bg = "white")
