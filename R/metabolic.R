pacman::p_load(readxl, tidyverse, plotly, heatmaply, grid)

metabolic_data <- read_excel("../data/annotations/metabolic/S_denitrificans_METABOLIC-G_out/METABOLIC_result.xlsx") %>%
  select(-contains("Hits"), -contains("Hmm.presence")) %>%
  gather(genome_id, hits, contains("Hit.numbers")) %>%
  mutate(genome_id = str_extract(genome_id, "(.*)(?=[.]Hit)"),
         presence = if_else(hits > 0, "Present", "Absent")) %>%
  rename_at(vars(contains(".")),funs(gsub("\\.", " ", .)))

metabolic_metadata <- read_excel("../data/metadata.xlsx")

# bubble plot -------------------------------------------------------------

#metabolism <- c("Nitrogen cycling", "Sulfur cycling", "As cycling", "Hydrogenases", "Methane metabolism", "Carbon fixation", "Chlorite reduction", "Selenate reduction", "Metal reduction", "Perchlorate reduction")
metabolism_color_dict <- read_csv("../data/metabolism_color_dict.csv")
element_cycling <- metabolism_color_dict %>%
  filter(group %in% c("Element Cycling", "Carbon")) %>%
  distinct() 
element_cycling_colors <- element_cycling$color
names(element_cycling_colors) <- element_cycling$Lump

bubble_plot <- metabolic_data %>%
  mutate(`Gene abbreviation` = str_remove(`Gene abbreviation`, 'group-')) %>%
  left_join(metabolic_metadata %>% dplyr::select(genome_id, species, gene_count)) %>%
  filter(hits > 0) %>%
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
         `Gene abbreviation` = factor(`Gene abbreviation`, levels = unique(`Gene abbreviation`[order(Lump)]))) %>%
  ggplot(aes(species, `Gene abbreviation`, color = Lump, label=Category)) +
  geom_point(ggplot2::aes(size = hits)) +
  scale_size_continuous(breaks = c(2e-05, 5e-05, 1e-04, 5e-04, 1e-03), name = "% metagenome") +
  scale_x_discrete(position = "top") +
  scale_color_manual(values = element_cycling_colors, name = "Metabolism Category") +
  theme_bw() +
  guides(col = guide_legend(ncol = 1)) +
  #guides(fill=guide_legend(title="Category")) +
  theme(axis.title.x=ggplot2::element_blank(), 
        axis.title.y=ggplot2::element_blank(),
        #legend.position = "none",
        #strip.background = element_blank(), 
        panel.spacing = unit(0,"line"), 
        panel.border = element_rect(size = 0.25, color = "black"),
        strip.text.y = element_text(angle = 180, size=8, lineheight=1))  +
  facet_grid(rows=vars(Category), switch = "y", scales = "free", space = "free_y",
             labeller = labeller(Category = label_wrap_gen(10)))

plotly::ggplotly(bubble_plot)


# carbon fixation ---------------------------------------------------------

c_fixation <- metabolism_color_dict %>%
  filter(Category == "Carbon fixation") %>%
  distinct()

c_fixation_colors <- c_fixation$color
names(c_fixation_colors) <- c_fixation$Lump

c_fix_n_genes <- metabolic_data %>%
  filter(Category == "Carbon fixation") %>%
  select(Category, Function, `Gene abbreviation`) %>%
  distinct() %>%
  group_by(Category, Function) %>%
  summarise(n_pathway_genes = n())

