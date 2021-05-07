require(pacman)

# set file paths ---------------------------------------------------------------
write_path <- "../../script_test/"
data_path <- "../data/"
write_figures <- paste0(write_path, "figures/")


# phylogenetic position of sulfuricella -----------------------------------
source("collapse_trees.R")

#plot tree iterations by SCG set - these are figures in supp file 2
source("facet_trees.R")

# plot METABOLIC hits -----------------------------------------------------
source("metabolic.R")

#plot bubble plot
cairo_pdf(paste0(write_figures,  "metabolic_bubble_plot.pdf"), 
          family="Arial Unicode MS",
          width = 10, height = 13)
bubble_plot
dev.off()

# plot occurrences --------------------------------------------------------

source("occurrences.R")

#plot occurrences
cairo_pdf(paste0(write_figures,  "occurrences.pdf"), 
          family="Arial Unicode MS",
          width = 13.33, height = 7.5)
occurrences
dev.off()


# plot thiosulfate disproportionation Gibbs free energy  ------------------

source("thermo.R")
cairo_pdf(paste0(write_figures,  "HS_activity_deltaG.pdf"), 
          family="Arial Unicode MS",
          width = 13.33, height = 7.5)
deltaG_plot
dev.off()


# D3 June 2019 geochem ----------------------------------------------------
source("geochem.R")
