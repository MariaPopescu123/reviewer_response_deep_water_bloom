#Maria Popescu

#this script:
# 1. calculates the Wedderburn number for BVR for every Date with a temperature
#    profile, a thermocline depth, and same-day wind stress (rLakeAnalyzer)
# 2. provides a diagnostic plot to visualize the Wedderburn number
# 3. makes a dataframe (final_wedderburn) of daily values, including log10(W) for RF analysis
#
# Wedderburn number: W = g' * h_epi^2 / (u*^2 * L)
# W >> 1 → wind can't tilt the thermocline much → stable stratification
# W < 1  → wind can upwell metalimnetic/hypolimnetic water → mixing likely
#
# Choices:
# - h_epi and the upper/lower layer split use the thermocline from 04_photic_temp_thermo.R
#   (rLakeAnalyzer's default meta.depths() puts the metalimnion top at/near the surface
#   on many days in BVR, especially the coarse YSI profiles of 2017-2018, forcing W to ~0)
# - u* uses same-day wind stress: stress is computed for every 1-min FCR met reading and
#   averaged over the day (mean of U^2, not mean(U)^2, so gusts aren't underweighted).
#   This matches the same-day temperature profile; the relevant wind events in a basin
#   this small last well under a day (1/4 internal seiche period ~ tens of minutes).
#   Week-scale wind history enters the RF separately through wind_week_avg.
#   Days without 1-min data (early 2015) fall back to the downscaled NLDAS daily mean.
# - W spans orders of magnitude, so log_wedderburn (log10 W) is the variable used in RF.
#   log10 W = 0 is the W = 1 mixing threshold.
#
# Inputs expected in the workspace from prior scripts:
# - bath (from 01_DataDownload.R)
# - temp_depths_interp, final_photic_thermo (from 04_photic_temp_thermo.R)
# - EDImetC (from 01_DataDownload.R), full_met (from 08_NLDAS_downscaling.R)
# Output written: CSVs/final_wedderburn.csv

required_objects <- c("bath", "temp_depths_interp", "final_photic_thermo", "EDImetC", "full_met")
missing_objects <- required_objects[!vapply(required_objects, exists, logical(1), inherits = TRUE)]
if (length(missing_objects) > 0) {
  stop("Missing required objects for 09_wedderburn.R: ",
       paste(missing_objects, collapse = ", "),
       ". Run 01_DataDownload.R, 04_photic_temp_thermo.R, and 08_NLDAS_downscaling.R first.")
}

#height of the anemometer on the FCR met station (m above surface), used by uStar()
#to scale wind to 10 m. Check this against the edi.389 metadata.
wnd_height <- 3

BVRbath <- bath|>
  filter(Reservoir == "BVR")|>
  select(Depth_m, SA_m2)

#one profile per Date (same May-October window as schmidt stability)
daily_temp_profiles <- temp_depths_interp |>
  filter(!is.na(Temp_C), DOY >= 133, DOY <= 286) |>
  mutate(Date = as.Date(Date)) |>
  group_by(Date, Depth_m) |>
  summarise(Temp_C = mean(Temp_C), .groups = "drop") |>
  arrange(Date, Depth_m)

daily_thermocline <- final_photic_thermo |>
  mutate(Date = as.Date(Date)) |>
  filter(!is.na(thermocline_depth)) |>
  distinct(Date, thermocline_depth)

#same-day kinematic wind stress per unit water density, tau/rho_w = u*^2 * rho_epi.
#uStar(U, h, 1)^2 = Cd * rhoAir * U10^2, so each day's u* = sqrt(mean_tau / rho_epi).
#Days with >10% missing 1-min wind are dropped (same rule as 08_NLDAS_downscaling.R).
daily_stress_edi <- EDImetC |>
  mutate(Date = as_date(DateTime)) |>
  group_by(Date) |>
  summarise(miss_wind = mean(is.na(WindSpeed_Average_m_s)),
            wind = mean(WindSpeed_Average_m_s, na.rm = TRUE),
            tau = mean(uStar(WindSpeed_Average_m_s[!is.na(WindSpeed_Average_m_s)], wnd_height, 1)^2),
            .groups = "drop") |>
  filter(miss_wind <= 0.10) |>
  transmute(Date, wind, tau, wind_source = "EDI 1-min")

daily_stress_nldas <- full_met |>
  mutate(Date = as.Date(Date)) |>
  filter(!is.na(WindSpeed_daily_Average_m_s), !Date %in% daily_stress_edi$Date) |>
  transmute(Date, wind = WindSpeed_daily_Average_m_s,
            tau = uStar(wind, wnd_height, 1)^2, wind_source = "NLDAS daily mean")

daily_stress <- bind_rows(daily_stress_edi, daily_stress_nldas) |>
  distinct(Date, .keep_all = TRUE)

#Wedderburn for one profile. Bathymetry is shifted for water level the same way as
#in 07_schmidt_stability.R (the bath frame is 0-14 m at full pond).
wedderburn_one_day <- function(wtr, depths, thermo, tau) {
  max_depth <- round(max(depths))
  bthD <- 0:max_depth
  bthA <- BVRbath$SA_m2[match(bthD + (14 - max_depth), BVRbath$Depth_m)]
  Ao <- bthA[1] #surface area at the current water level

  out <- tibble(epi_dens = NA_real_, hypo_dens = NA_real_, uStar = NA_real_, wedderburn = NA_real_)
  if (length(wtr) < 3 || any(is.na(bthA)) || thermo <= 0 || thermo >= max(depths)) return(out)

  epi_dens  <- layer.density(0, thermo, wtr, depths, bthA, bthD)
  hypo_dens <- layer.density(thermo, max(depths), wtr, depths, bthA, bthD)
  uS <- sqrt(tau / epi_dens)

  tibble(epi_dens = epi_dens, hypo_dens = hypo_dens, uStar = uS,
         wedderburn = wedderburn.number(delta_rho = hypo_dens - epi_dens, metaT = thermo,
                                        uSt = uS, Ao = Ao, AvHyp_rho = hypo_dens))
}

final_wedderburn <- daily_temp_profiles |>
  inner_join(daily_thermocline, by = "Date") |>
  inner_join(daily_stress |> select(Date, tau), by = "Date") |>
  group_by(Date) |>
  group_modify(~ wedderburn_one_day(.x$Temp_C, .x$Depth_m, .x$thermocline_depth[1], .x$tau[1])) |>
  ungroup() |>
  left_join(daily_thermocline, by = "Date") |>
  left_join(daily_stress, by = "Date") |>
  mutate(Year = year(Date)) |>
  #no density difference across the thermocline → Wedderburn is undefined
  mutate(wedderburn = if_else(is.finite(wedderburn) & wedderburn > 0 & hypo_dens > epi_dens,
                              wedderburn, NA_real_),
         log_wedderburn = log10(wedderburn)) |>
  select(Date, Year, wind_source, wind, tau, thermocline_depth, epi_dens, hypo_dens, uStar,
         wedderburn, log_wedderburn)

#how many Dates got a value, per year
final_wedderburn |>
  group_by(Year) |>
  summarise(n_dates = n(), n_wedderburn = sum(!is.na(wedderburn)),
            median_W = median(wedderburn, na.rm = TRUE),
            min_log_W = min(log_wedderburn, na.rm = TRUE),
            max_log_W = max(log_wedderburn, na.rm = TRUE), .groups = "drop") |>
  print(n = Inf)

#diagnostic plot to visualize the Wedderburn number
wedderburn_plot <- ggplot(final_wedderburn |> filter(!is.na(log_wedderburn)),
                          aes(x = yday(Date), y = log_wedderburn, color = factor(Year), group = Year)) +
  geom_line() +
  geom_hline(yintercept = 0, linetype = "dashed") + #W = 1
  labs(
    x = "Day of Year",
    y = expression(log[10]~"Wedderburn Number"),
    color = "Year"
  ) +
  theme_minimal()
wedderburn_plot

write.csv(final_wedderburn, here::here("CSVs", "final_wedderburn.csv"), row.names = FALSE)
