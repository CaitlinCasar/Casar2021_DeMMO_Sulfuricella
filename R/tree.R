#tutorial https://yulab-smu.top/treedata-book/index.html
#BiocManager::install("ggtree")

pacman::p_load(tidyverse, ggtree, ape, extrafont, readxl)

tree <- read.tree("../data/tree/universal_tree_of_life.tre")
betaproteobacteria <- read_csv("../data/tree/betaproteobacteria.csv")
collapsed_nodes <- read_csv("../data/tree/collapsed_nodes.csv")

tree_genomes <- read_excel("../data/tree/tree_genome info.xlsx")
genome_summary <- read_delim("../data/tree/Genomes_summary_info.tsv", delim="\t") %>%
  filter(class == "Betaproteobacteria")

missing_genomes <- genome_summary %>%
  full_join(tree_genomes, by = c("specific_name" = "Species")) %>%
  mutate(assembly_id = if_else(is.na(assembly_id), `Genome ID`, assembly_id)) %>%
  filter(!is.na(assembly_id))

write_csv(missing_genomes, "betaproteobacteria_for_tree.csv")

taxa <- data.frame(taxa = tree$tip.label) %>%
  separate(taxa, c("x", "accession", "domain", "phylum", "class", "genus", "species", "strain"), sep = "_")

nitro_tree <- extract.clade(tree, 1917, root.edge = 0, collapse.singles = TRUE,
                       interactive = FALSE)

nitro_tree$tip.label <- if_else(str_detect(nitro_tree$tip.label, "Betaproteobacteria_"), 
                           str_extract(nitro_tree$tip.label, "(?<=Bacteria_Proteobacteria_Betaproteobacteria_)(.*)"),
                           if_else(str_detect(nitro_tree$tip.label, "Hydrogenophilalia"),
                                   str_extract(nitro_tree$tip.label, "(?<=Bacteria_Proteobacteria_Hydrogenophilalia_)(.*)"),
                                   if_else(str_detect(nitro_tree$tip.label, "bin"), "Sulfuricella_sp._Bin.1",
                                           nitro_tree$tip.label)))
                                   
  
notrosomonadales <- data.frame(taxa = nitro_tree$tip.label) %>%
  separate(taxa, c("genus", "species", "strain"), sep = "_") %>%
  left_join(betaproteobacteria) %>%
  mutate(famiy = if_else(order == "Nitrosomonadales", famiy, order))

taxa_colors <- c(rep("black", 5), "#DAA520", "#da3c20", rep("black",6))
names(taxa_colors) <- c(notrosomonadales %>% select(famiy) %>% distinct() %>% pull(), "Oryzomicrobium_terrae_TPP412", "Hydrogenophilus_thermoluteolus_TH-1", 0)

  
groups <- split(nitro_tree$tip.label, notrosomonadales$famiy)

grouped_tree <- groupOTU(nitro_tree,  groups)

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
  mapply(function(x) 
    geom_point2(
      aes_string(subset=paste("node ==", x)), 
      size=5, shape="\u25C4", fill="gray"
    ), 
    x=collapsed_nodes$node
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


cairo_pdf("../figures/sulfuricella_tree.pdf", 
          family="Arial Unicode MS",
          width = 10, height = 7)
tree_figure
dev.off()
  
  
  #scale_color_manual(values = taxa_colors) +
  #geom_cladelabel()
gzoom(colored_tree, grep("Deltaproteobacteria", tree2$tip.label), xmax_adjust=2)

plotly::ggplotly(tree_figure)


# tutorial ----------------------------------------------------------------
data(chiroptera)
groupInfo <- split(chiroptera$tip.label, gsub("_\\w+", "", chiroptera$tip.label))
chiroptera <- groupOTU(chiroptera, groupInfo)
p <- ggtree(chiroptera, aes(color=group)) + geom_tiplab() 
gzoom(p, grep("Plecotus", chiroptera$tip.label), xmax_adjust=2)


phyla <- taxa %>% select(phylum) %>% distinct()

  
  
  
  