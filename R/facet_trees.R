pacman::p_load(tidyverse, ggtree, ape, extrafont, readxl)

dirs <- list.dirs(paste0(data_path, "tree/tree_iterations"), recursive = F)

trees <- list()
removed_genomes <- list()
for(i in 1:length(dirs)){
  files <- list.files(dirs[i], full.names = T)
  
  tree_title <- str_extract(dirs[i], "(?<=/tree_iterations/)(.*)")
  message(paste0("importing ", tree_title, "..."))
  #read tree data 
  tree <- read.tree(files[str_detect(files, "[.]tre")])
  genome_summary <- read_delim(files[str_detect(files, "summary_info")], delim = "\t")
  removed_genomes[[i]] <- genome_summary %>%
    select(assembly_id, label, in_final_tree) %>%
    rename(!!tree_title := "in_final_tree")
  if(!is.null(tree)){
    genome_summary <- genome_summary  %>%
      mutate(NCBI_family = if_else(NCBI_order == "Nitrosomonadales", NCBI_family, NCBI_order),
             NCBI_family = if_else(label == "Candidatus_Gallionella_acididurans", "Gallionellaceae", NCBI_family),
             NCBI_species = if_else(label == "Candidatus_Gallionella_acididurans", "Candidatus Gallionella acididurans", NCBI_species),
             NCBI_family = if_else(label ==  'bin_1_Betaproteobacteria', "Sulfuricellaceae", NCBI_family),
             NCBI_species = if_else(label == "bin_1_Betaproteobacteria", "Sulfuricella sp. D3-1", NCBI_species))
    
    taxa <- data.frame(label = tree$tip.label) %>%
      left_join(genome_summary)
    
    tree$tip.label <- taxa %>% 
      mutate(label = NCBI_species) %>%
      pull()
    
    groups <- split(tree$tip.label, taxa$NCBI_family)
    
    grouped_tree <- groupOTU(tree,  groups)
    
    tree_taxa <- c("Sulfuricellaceae", "Gallionellaceae", genome_summary %>% select(NCBI_family) %>% 
      filter(!NCBI_family %in% c("Sulfuricellaceae", "Gallionellaceae")) %>%
      distinct() %>% pull(), 0)
    
    taxa_colors <- c("#DAA520", "#da3c20", rep("gray",length(tree_taxa) -2))
    names(taxa_colors) <- tree_taxa
    
    if(length(grouped_tree$edge.length) > 1){
    colored_tree <- ggtree(grouped_tree, aes(color=group, label = group))+ 
      geom_text2(aes(subset=!isTip, label=node), hjust=-.3, size = 2) + 
      geom_nodelab(size = 3, col= "black", hjust = -.3) +
      geom_tiplab(size = 3) +
      geom_treescale() +
      scale_color_manual(values = taxa_colors) +
      ggtitle(tree_title)
    
    trees[[i]] <- colored_tree
    names(trees)[[i]] <- tree_title
    }
  }
}

genome_info <- reduce(removed_genomes, full_join) %>%
  mutate_at(vars(-assembly_id, -label), ~ifelse(. == "Yes", 1, NA)) %>%
  select(where(~!any(is.na(.))))

#plot trees by type
tree_types <- c("beta", "proteo", "universal")
for(i in 1:length(tree_types)){
  trees_list <- trees[str_detect(names(trees), tree_types[i])]
  tree_plots <- gridExtra::arrangeGrob(grobs = trees_list, nrow = 3)
  cairo_pdf(paste0(write_figures, tree_types[i], "_tree_iterations.pdf"), 
            family="Arial Unicode MS",
            width = 20, height = 30)
  gridExtra::grid.arrange(tree_plots)
  dev.off()
}

