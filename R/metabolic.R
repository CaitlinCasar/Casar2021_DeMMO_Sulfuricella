pacman::p_load(readxl, tidyverse, plotly, heatmaply, grid)

metabolic_data <- read_excel(paste0(data_path, "annotations/metabolic/S_denitrificans_METABOLIC-G_out/METABOLIC_result.xlsx")) %>%
  select(-contains("Hits"), -contains("Hmm.presence")) %>%
  gather(genome_id, hits, contains("Hit.numbers")) %>%
  mutate(genome_id = str_extract(genome_id, "(.*)(?=[.]Hit)"),
         presence = if_else(hits > 0, "Present", "Absent")) %>%
  rename_at(vars(contains(".")),funs(gsub("\\.", " ", .)))

metabolic_metadata <- read_excel(paste0(data_path, "metadata.xlsx"))

fegenie_data <- read_csv(paste0(data_path, "annotations/fegenie/FeGenie-heatmap-data.csv")) %>%
  pivot_longer(-X, names_to = "genome_id", values_to = "hits") %>%
  mutate(genome_id = str_remove(genome_id, ".faa")) %>%
  rename(Category = "X") %>%
  filter(hits > 0 & genome_id != "bin_2_Rhizobiales" & Category %in% c("iron_reduction", "iron_oxidation", "possible_iron_oxidation_and_possible_iron_reduction", "probable_iron_reduction")) %>%
  left_join(metabolic_metadata) %>%
  select(species, Category, hits)

# bubble plot -------------------------------------------------------------

#metabolism <- c("Nitrogen cycling", "Sulfur cycling", "As cycling", "Hydrogenases", "Methane metabolism", "Carbon fixation", "Chlorite reduction", "Selenate reduction", "Metal reduction", "Perchlorate reduction")
metabolism_color_dict <- read_csv(paste0(data_path, "metabolism_color_dict.csv"))
element_cycling <- metabolism_color_dict %>%
  filter(group %in% c("Element Cycling", "Carbon")) %>%
  distinct() 
element_cycling_colors <- element_cycling$color
names(element_cycling_colors) <- element_cycling$Lump

bubble_plot <- metabolic_data %>%
  mutate(`Gene abbreviation` = str_remove(`Gene abbreviation`, 'group-')) %>%
  left_join(metabolic_metadata %>% dplyr::select(genome_id, species, gene_count)) %>%
  filter(hits > 0  & !Category %in% c("Amino acid utilization","Oxidative phosphorylation",
                                      "Oxygen metabolism (Oxidative phosphorylation Complex IV)", 
                                      "Ethanol fermentation", "Complex carbon degradation", 
                                      "Aromatics degradation", "Fatty acid degradation")) %>%
  filter(genome_id != "bin_2_Rhizobiales") %>%
  group_by(species) %>%
  mutate(hits = (hits/gene_count)*100) %>%
  group_by(species, Function, Category, `Gene abbreviation`) %>%
  summarise(hits = sum(hits)) %>%
  inner_join(element_cycling) %>%
  ungroup() %>%
  mutate(Category = if_else(Category == "Metal reduction", "Fe/Mn reduction", Category),
         Category = if_else(Category == "Urea utilization", "Nitrogen cycling", Category),
         Category = if_else(Category == "Halogenated compound utilization", "Halogen cycling", Category),
         Category = if_else(Category == "Perchlorate reduction", "Halogen cycling", Category),
         Category = if_else(Category == "Chlorite reduction", "Halogen cycling", Category),
         Lump = as.factor(Lump),
         `Gene abbreviation` = factor(`Gene abbreviation`, levels = unique(`Gene abbreviation`[order(Lump)])),
         species = factor(species, levels = c("Prosthecomicrobium sp. DeMMO3_2", "S. sp. D3-1", "S. denitrificans", "S. sp. T08"))) %>%
  ggplot(aes(species, `Gene abbreviation`, color = Lump, label=Category)) +
  geom_point(ggplot2::aes(size = hits)) +
  theme_bw() +
  guides(col = guide_legend(ncol = 1)) +
  guides(color=guide_legend(title="Category"),
         size=guide_legend(title="% MAG")) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),
        axis.title.x=ggplot2::element_blank(), 
        axis.title.y=ggplot2::element_blank(),
        text = element_text(size = 12),
        legend.key.size = unit(0.5, "cm"),
        #legend.position = "none",
        #strip.background = element_blank(), 
        panel.spacing = unit(0,"line"), 
        panel.border = element_rect(size = 0.25, color = "black"),
        strip.text.y = element_text(angle = 180, size=12, lineheight=1))  +
  facet_grid(rows=vars(Category), switch = "y", scales = "free", space = "free_y",
             labeller = labeller(Category = label_wrap_gen(10)))

