pacman::p_load(tidyverse, lubridate, zoo)

#measurement units:
#flow rate mL/min
#temp C
#cond uS
#TDS ppm
#gas nM
#DIC mM 
#ions/metals mg/L except S2 which is ug/L

geochemistry <- read_csv(paste0(data_path, "geochem.csv")) %>%
  mutate(date = as.Date(mdy(date), "%m-%d-%Y"),
         date =as.yearmon(date, "%m/%Y"),
         S2 = S2*0.001) %>% #convert units to mg/L
  filter(date == "June 2019" & site == "D3") %>%
  select(-CH4, -H2, -CO2, -CO) %>%
  select_if(!is.na(.))

#average gas measurements and convert from nM to mg/L
averaged_data <- read_csv(paste0(data_path, "geochem.csv")) %>%
  mutate(CH4 = (CH4*10^-9)*16.04*1000,
         H2 = (H2*10^-9)*1.00794*1000,
         CO2 = (CO2*10^-9)*44.01*1000,
         CO = (CO*10^-9)*28.01*1000) %>%
  group_by(site) %>%
  summarise(CH4 = mean(CH4, na.rm = T),
            H2 = mean(H2, na.rm = T),
            CO2 = mean(CO2, na.rm = T),
            CO = mean(CO, na.rm = T)) %>%
  filter(site == "D3") %>%
  select(-site)


geochemistry_all <- geochemistry %>%
  bind_cols(averaged_data) %>%
  mutate_all(as.character) %>%
  pivot_longer(everything(), names_to = "measurement", values_to = "value") %>%
  mutate(unit = if_else(measurement %in% c("NO3","NH4","Fe2","S2","DO","SO4","Cl","F", "Mg","Ca","Na","Si",
                                           "Fe","Mn","Al","Ar","Ba","B","Li","Ni", "CH4", "CO", "H2", "CO2"), "mg/L", " "),
         unit = if_else(measurement == "temp", "Celsius", unit),
         unit = if_else(measurement == "flow rate", "mL/minute", unit),
         unit = if_else(measurement == "cond", "μS", unit),
         unit = if_else(measurement == "TDS", "ppm", unit),
         unit = if_else(measurement == "DIC", "mM", unit))

write_csv(geochemistry_all, paste0(write_path, "geochem_June2019.csv"))
