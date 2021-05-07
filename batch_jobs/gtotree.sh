#!/bin/bash
#SBATCH -A p30777               # Allocation
#SBATCH -p long                # Queue
#SBATCH -t 10:00:00             # Walltime/duration of the job
#SBATCH -N 1                    # Number of Nodes
#SBATCH -n 1                    # Number of cores
#SBATCH --mem=0G               # Memory per node in GB needed for a job. Also see --mem-per-cpu
#SBATCH --mail-user=casar@u.northwestern.edu  # Designate email address for job communications
#SBATCH --mail-type=ALL     # Events options are job BEGIN, END, NONE, FAIL, REQUEUE
#SBATCH --job-name="gtotree"       # Name of job


module load anaconda3
source activate gtotree

cd /projects/p30777/S_denitrificans/tree

echo running betaproteobacteria proteins...

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Betaproteobacteria -t -j 4 -o beta_tree_0.5 -G 0.5 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Betaproteobacteria -t -j 4 -o beta_tree_0.6 -G 0.6 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Betaproteobacteria -t -j 4 -o beta_tree_0.7 -G 0.7 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Betaproteobacteria -t -j 4 -o beta_tree_0.8 -G 0.8 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Betaproteobacteria -t -j 4 -o beta_tree_0.9 -G 0.9 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Betaproteobacteria -t -j 4 -o beta_tree_1.0 -G 1.0 -P

echo running proteobacteria proteins...

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Proteobacteria -t -j 4 -o proteo_tree_0.5 -G 0.5 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Proteobacteria -t -j 4 -o proteo_tree_0.6 -G 0.6 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Proteobacteria -t -j 4 -o proteo_tree_0.7 -G 0.7 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Proteobacteria -t -j 4 -o proteo_tree_0.8 -G 0.8 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Proteobacteria -t -j 4 -o proteo_tree_0.9 -G 0.9 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Proteobacteria -t -j 4 -o proteo_tree_1.0 -G 1.0 -P

echo running universal proteins...

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Universal -t -j 4 -o universal_tree_0.5 -G 0.5 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Universal -t -j 4 -o universal_tree_0.6 -G 0.6 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Universal -t -j 4 -o universal_tree_0.7 -G 0.7 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Universal -t -j 4 -o universal_tree_0.8 -G 0.8 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Universal -t -j 4 -o universal_tree_0.9 -G 0.9 -P

time GToTree -a assembly_ids_betaproteobacteria_for_tree_clean.txt -f D3_Bin1.txt -H Universal -t -j 4 -o universal_tree_1.0 -G 1.0 -P
