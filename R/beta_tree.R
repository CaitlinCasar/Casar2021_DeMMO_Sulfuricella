pacman::p_load(tidyverse, ggtree, ape, extrafont, readxl)

files <- list.files("../../data/tree/tree_iterations/beta_tree_0.7/", full.names = T)

#read tree data 

tree <- read.tree(files[str_detect(files, "[.]tre")])

genome_summary <- read_delim(files[str_detect(files, "summary_info")], delim = "\t")  %>%
  mutate(NCBI_family = if_else(NCBI_order == "Nitrosomonadales", NCBI_family, NCBI_order),
         NCBI_family = if_else(NCBI_class %in% c("Gammaproteobacteria", "Acidithiobacillia"), NCBI_class, NCBI_family),
         NCBI_family = if_else(label == "Candidatus_Gallionella_acididurans", "Gallionellaceae", NCBI_family),
         NCBI_species = if_else(label == "Candidatus_Gallionella_acididurans", "Candidatus Gallionella acididurans", NCBI_species),
         NCBI_family = if_else(label ==  'bin_1_Betaproteobacteria', "Sulfuricellaceae", NCBI_family),
         NCBI_species = if_else(label == "bin_1_Betaproteobacteria", "Sulfuricella sp. D3-1", NCBI_species))

n_branches <- genome_summary %>%
  group_by(NCBI_family) %>%
  summarise(n_branches = n()) %>%
  rename(taxa = "NCBI_family")

collapsed_nodes <- read_csv(files[str_detect(files, "collapsed_nodes")]) %>%
  left_join(n_branches)

taxa <- data.frame(label = tree$tip.label) %>%
  left_join(genome_summary)

tree$tip.label <- taxa %>% 
  mutate(label = NCBI_species) %>%
  pull()

groups <- split(tree$tip.label, taxa$NCBI_family)

grouped_tree <- groupOTU(tree,  groups)

tree_taxa <- c(c("Sulfuricellaceae", "Gallionellaceae"), genome_summary %>% select(NCBI_family) %>% filter(!NCBI_family %in% c("Gallionellaceae", "Sulfuricellaceae")) %>%
                 distinct() %>% pull(), 0)

taxa_colors <- c("#DAA520", "#da3c20", rep("gray",length(tree_taxa) -2))
names(taxa_colors) <- tree_taxa


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



