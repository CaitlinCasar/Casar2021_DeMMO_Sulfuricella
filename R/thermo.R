#load tidyverse library
pacman::p_load(tidyverse, CHNOSZ)

activities <- read_csv("https://raw.githubusercontent.com/CaitlinCasar/Casar2020_DeMMO_MineralHostedBiofilms/master/orig_data/DeMMO_SpecE8_aqueousGas.csv") %>%
  pivot_longer(`Ca+2`:CO, names_to = "react_prod", values_to = "activity") %>% #pivot from wide to long for joining
  filter(Site == "DeMMO3") %>%
  select(-Site)

HS_activity = -6.913400
iterations = c(-5:-1, 1:5)
HS_iterations <- list()

for(i in 1:length(iterations)){
  HS_iterations[[i]] <- activities %>%
    mutate(activity = if_else(react_prod == "HS-", activity*iterations[i], activity),
           HS_activity = HS_activity*iterations[i],
           iteration = i)
}

HS_iterations_df <- do.call(bind_rows,HS_iterations)

#import DeMMO mineral reactions
reactions <- read_csv("https://raw.githubusercontent.com/CaitlinCasar/Casar2020_DeMMO_MineralHostedBiofilms/master/orig_data/reactions_aq_gas.csv",
                      col_types = cols (.default = "c"))

thermo_db <- thermo()$obigt %>% as_tibble()

thiosulfate_disproportionation <- c(40, "thiosulfate", "thiosulfate", 
                                    "S2O3-2", "H2O", NA, NA,
                                    "SO4-2", "HS-", "H+", NA, NA,
                                    "2", "-1", "-1", NA, NA,
                                    "1", "1", "-1", NA, NA,
                                    "aq", "aq", NA, NA,
                                    "aq", "aq", "aq", NA, NA)

names(thiosulfate_disproportionation) <- colnames(reactions)

reactions <- reactions %>%
  bind_rows(thiosulfate_disproportionation)


#set temperature units to Kelvin
T.units("K")

#set energy units to joules
E.units("J")

logK <- reactions %>%
  filter(rxn.number == "40") %>%
  pivot_longer(reactant.a:state.i,
               names_to = c(".value", "set"),
               names_pattern = "(.+).(.+)") %>% #pivot from wide to long dataframe
  unite("react_prod", reactant:product, na.rm = TRUE, remove = F) %>% #unite the reactants and products into one column 
  filter(!react_prod == "") %>% #remove any rows with missing react_prod values
  mutate(coeff = as.numeric(coeff)) %>%
  group_by(rxn.number) %>% #group by reaction number for calculations
  summarise(LogK = subcrt(react_prod, coeff, state, T=289.35)$out$logK) #calculate logK using in situ DeMMO3 temperature for all other reactions 



logQ <- reactions %>%
  filter(rxn.number == "40") %>%
  pivot_longer(reactant.a:state.i,
               names_to = c(".value", "set"),
               names_pattern = "(.+).(.+)") %>% #pivot from wide to long 
  unite("react_prod", reactant:product, na.rm = TRUE, remove = F) %>% #unite the reactant and product columns into one column called react_prod 
  left_join(HS_iterations_df) %>% #join with the activities data 
  filter(!is.na(activity)) %>% #remove any activities with NA values 
  mutate(coeff = as.numeric(coeff),
         logQ = if_else(!is.na(reactant), -abs(coeff)*activity, abs(coeff)*activity)) %>% #multiply each species by its stoichiometric coefficient 
  group_by(rxn.number, HS_activity, iteration) %>% #group on the reaction number and site 
  summarise(logQ = sum(logQ)) #calculate logQ 


deltaG <- logK %>%
  left_join(logQ) %>% #join the logK and logQ tables 
  left_join(reactions %>% select(rxn.number, e.transfer, reactant.a)) %>% #add the reaction number, number of electrons transferred, and minerals from each reaction 
  rename(mineral = "reactant.a") %>% #rename reactant.a to mineral for clarity 
  mutate(e.transfer = as.numeric(e.transfer),
         deltaG = (-2.303*8.314*283.45*(LogK-logQ))/(e.transfer*1000)) #calculate deltaG for each reaction at each site 


deltaG_plot <- deltaG %>%
  ggplot(aes(deltaG, HS_activity)) +
  geom_line() + 
  geom_vline(xintercept = -31.083030, linetype = "dashed", color = "gray") +
  scale_x_reverse() +
  ylab("log activity HS-") + 
  labs(x=expression(Delta~G[r]~'kJ/mol'~e^{textstyle("-")})) 
  
