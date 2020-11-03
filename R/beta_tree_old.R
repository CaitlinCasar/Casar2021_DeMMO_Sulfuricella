
pacman::p_load(tidyverse, ggtree, ape, extrafont, readxl)

tree <- read.tree("../data/tree/betaproteobacteria_proteins_tree/caitlinstree3.tre")
collapsed_nodes <- read_csv("../data/tree/betaproteobacteria_proteins_tree/collapsed_nodes.csv")
betaproteobacteria <- read_csv("../data/tree/betaproteobacteria.csv")
genome_taxonomy <- read_csv("../data/tree/betaproteobacteria_proteins_tree/tree_genome info.csv") %>%
  mutate(label = str_replace_all(specific_name, " ", "_"))

sulfuricellaceae <- genome_taxonomy %>%
  filter(family == "Sulfuricellaceae")

genome_summary <- read_delim("../data/tree/betaproteobacteria_proteins_tree/Genomes_summary_info.tsv", delim="\t") %>%
  left_join(genome_taxonomy) %>%
  mutate(family = if_else(order == "Nitrosomonadales", family, order),
         family = if_else(label == "Candidatus_Gallionella_acididurans", "Gallionellaceae", family),
         family = if_else(specific_name %in% c(sulfuricellaceae$specific_name, "Sulfuricella sp. T08") | label %in% c('Sulfurimicrobium_lacus_skT11', 'bin_1_Betaproteobacteria'), "Sulfuricellaceae", family))

duplicated_genomes <- genome_summary %>% 
  filter(is.na(phylum)) %>%
  separate(label, c("genus", "species", "strain"), "_") %>%
  mutate(specific_name = paste0(genus, " ", species)) %>%
  inner_join(genome_summary, by = c("genus", "specific_name"))

clean_tree <- drop.tip(tree, c(duplicated_genomes$assembly_id.x, "GCA_011764585.1_Bacteria_Proteobacteria_Betaproteobacteria_Nitrosomonadales_bacterium_skT11_skT11", "Sulfuricella_T08", "GCF_000023745.1_Bacteria_Proteobacteria_Betaproteobacteria_Methylovorus_glucosotrophus_SIP3−4"))


taxa <- data.frame(label = clean_tree$tip.label) %>%
  left_join(genome_summary)

clean_tree$tip.label <- taxa %>% 
  mutate(specific_name = if_else(is.na(specific_name), label, specific_name),
         specific_name = if_else(label == "bin_1_Betaproteobacteria", "Sulfuricella_D3_Bin1", specific_name)) %>%
  select(specific_name) %>%
  pull()

groups <- split(clean_tree$tip.label, taxa$family)

grouped_tree <- groupOTU(clean_tree,  groups)

taxa_colors <- c("black", "#DAA520", rep("black", 4), "#da3c20", rep("black",3))
names(taxa_colors) <- c(genome_summary %>%filter(!is.na(family)) %>% select(family) %>% distinct() %>% pull() , 0)


colored_tree <- ggtree(grouped_tree, aes(color=group, label = group))+ 
  #geom_text2(aes(subset=!isTip, label=node), hjust=-.3, size = 2) + 
  geom_nodelab(size = 3, col= "black", hjust = -.3) +
  geom_tiplab(size = 3)  

#collapse the tree
collapsed_tree <- colored_tree %>%
  collapse(node=collapsed_nodes$node[1]) 

for(i in 2:length(collapsed_nodes$node)){
  message(paste0("Collapsing node ",  collapsed_nodes$node[i], "..."))
  collapsed_tree <- collapsed_tree %>% collapse(node=collapsed_nodes$node[i])
}

#plot the tree 
tree_figure <- collapsed_tree + 
  mapply(function(x, y) 
    geom_point2(
      aes_string(subset=paste("node ==", x)), 
      size=y, shape="\u25C4", fill="gray"
    ), 
    x=collapsed_nodes$node,
    y=log(collapsed_nodes$n_branches)*2
  ) +
  mapply(function(x) 
    geom_text2(
      aes_string(subset=paste("node ==", x)), 
      size=3, hjust = -.6
    ), 
    x=collapsed_nodes$node
  ) +
  geom_treescale() +
  scale_color_manual(values = taxa_colors) +
  theme(text=element_text(family="Arial Unicode MS"))


cairo_pdf("../figures/sulfuricella_tree_beta_proteins.pdf", 
          family="Arial Unicode MS",
          width = 10, height = 7)
tree_figure
dev.off()



