#tutorials for pipeline: https://github.com/biovcnet/topic-metagenomics

#install bbmap https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/installation-guide/
wget https://sourceforge.net/projects/bbmap/files/BBMap_38.86.tar.gz/download -O BBMap_38.86.tar.gz
tar -xvzf BBMap_38.86.tar.gz

#install fastqc
wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip
unzip fastqc_v0.11.9.zip

# start interactive job on Quest
srun --account=p30777 --time=04:00:00 --partition=short --mem=48G --pty bash

module load python
module load spades
module load java   

#Trim adapters
# 'ordered' means to maintain the input order as produced by clumpify.sh
~/bbmap/bbduk.sh in=S_denitrificans_S6_R1_001.fastq.gz in2=S_denitrificans_S6_R2_001.fastq.gz out=trimmed.fq.gz ktrim=r k=23 mink=11 hdist=1 tbo tpe minlen=70 ref=adapters ordered ow=t


###output###
Version 38.86

Set ORDERED to true
maskMiddle was disabled because useShortKmers=true
0.271 seconds.
Initial:
Memory: max=23417m, total=23417m, free=22684m, used=733m

Added 217135 kmers; time:   1.018 seconds.
Memory: max=23417m, total=23417m, free=22318m, used=1099m

Input is being processed as paired
Started output streams: 0.170 seconds.
Processing time:      122.165 seconds.

Input:                    3932770 reads     510309419 bases.
KTrimmed:                 23903 reads (0.61%)   680063 bases (0.13%)
Trimmed by overlap:       17082 reads (0.43%)   382977 bases (0.08%)
Total Removed:            303096 reads (7.71%)  18317164 bases (3.59%)
Result:                   3629674 reads (92.29%)  491992255 bases (96.41%)

Time:                           123.357 seconds.
Reads Processed:       3932k  31.88k reads/sec
Bases Processed:        510m  4.14m bases/sec
###output###

#Remove synthetic artifacts and spike-ins by kmer-matching
# 'cardinality' will generate an accurate estimation of the number of unique kmers in the dataset using the LogLog algorithm
~/bbmap/bbduk.sh in=trimmed.fq.gz out=filtered.fq.gz k=31 ref=artifacts,phix ordered cardinality ow=t

###output###
Input:                    3629674 reads     491992255 bases.
Contaminants:             0 reads (0.00%)   0 bases (0.00%)
Total Removed:            0 reads (0.00%)   0 bases (0.00%)
Result:                   3629674 reads (100.00%)   491992255 bases (100.00%)
Unique 31-mers:           36950039

Time:                           77.178 seconds.
Reads Processed:       3629k  47.03k reads/sec
Bases Processed:        491m  6.37m bases/sec
###output###

#Quality-trim and entropy filter the remaining reads.
# 'entropy' means to filter out reads with low complexity
# 'maq' is 'mininum average quality' to filter out overall poor reads
~/bbmap/bbduk.sh in=filtered.fq.gz out=S_denitrificans_qtrimmed.fq.gz qtrim=r trimq=10 minlen=70 ordered maxns=0 maq=8 entropy=.95 ow=t

###output###
Input:                    3629674 reads     491992255 bases.
QTrimmed:                 844 reads (0.02%)   133670 bases (0.03%)
Low quality discards:     3838 reads (0.11%)  525610 bases (0.11%)
Low entropy discards:     128472 reads (3.54%)  17790795 bases (3.62%)
Total Removed:            133230 reads (3.67%)  18450075 bases (3.75%)
Result:                   3496444 reads (96.33%)  473542180 bases (96.25%)

Time:                           54.113 seconds.
Reads Processed:       3629k  67.08k reads/sec
Bases Processed:        491m  9.09m bases/sec
###output###

#trim reads with trimmomatic
java -jar /home/cpc7770/Trimmomatic-0.39/trimmomatic-0.39.jar PE S_denitrificans_S6_R1_001.fastq.gz S_denitrificans_S6_R2_001.fastq.gz S_denitrificans_forward_paired.fq.gz S_denitrificans_forward_unpaired.fq.gz S_denitrificans_reverse_paired.fq.gz S_denitrificans_reverse_unpaired.fq.gz  ILLUMINACLIP:/home/cpc7770/Trimmomatic-0.39/adapters/TruSeq3-SE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:70

#lowering the minlength to 39 produces ~50 fewer contigs and ~3k higher contig N50
java -jar /home/cpc7770/Trimmomatic-0.39/trimmomatic-0.39.jar PE S_denitrificans_S6_R1_001.fastq.gz S_denitrificans_S6_R2_001.fastq.gz S_denitrificans_forward_paired.fq.gz S_denitrificans_forward_unpaired.fq.gz S_denitrificans_reverse_paired.fq.gz S_denitrificans_reverse_unpaired.fq.gz  ILLUMINACLIP:/home/cpc7770/Trimmomatic-0.39/adapters/TruSeq3-SE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

#check the trimmed and original files for quality with fastqc
/home/cpc7770/FastQC/fastqc S_denitrificans_qtrimmed.fq.gz S_denitrificans_forward_paired.fq.gz S_denitrificans_reverse_paired.fq.gz S_denitrificans_S6_R1_001.fastq.gz S_denitrificans_S6_R2_001.fastq.gz

# Assembly using tadpole
~/bbmap/tadpole.sh in=S_denitrificans_qtrimmed.fq.gz out=tadpole_contigs.fasta k=124 ow=t prefilter=2 prepasses=auto

# Assembly quality-trimmed reads using SPAdes
#thie produces 4k contigs/scaffolds
spades.py -o S_denitrificans_spades --12 S_denitrificans_qtrimmed.fq.gz --isolate -t 12
#this produces 4149 scaffolds and 4275 contigs
spades.py -o S_denitrificans_spades_careful --12 S_denitrificans_qtrimmed.fq.gz --careful -t 12

#calculate average read coverage 
~/bbmap/bbmap.sh in=S_denitrificans_qtrimmed.fq.gz ref=S_denitrificans_spades/contigs.fasta covstats=covstats.txt

   ------------------   Results   ------------------

Genome:                 1
Key Length:             13
Max Indel:              16000
Minimum Score Ratio:    0.56
Mapping Mode:           normal
Reads Used:             3496444 (473542180 bases)

Mapping:            810.898 seconds.
Reads/sec:        4311.82
kBases/sec:       583.97


Pairing data:     pct pairs num pairs   pct bases    num bases

mated pairs:       97.8619%     1710843    97.7735%      462998570
bad pairs:          0.9141%       15981     0.9987%        4729070
insert size avg:    219.42


Read 1 data:        pct reads num reads   pct bases    num bases

mapped:            99.3036%     1736048    99.3062%      235096723
unambiguous:       98.9510%     1729883    98.9607%      234278792
ambiguous:          0.3526%        6165     0.3455%         817931
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   81.0738%     1417350    80.4693%      190502316
semiperfect site:  81.8002%     1430049    81.2175%      192273652
rescued:            0.4136%        7230

Match Rate:             NA         NA    95.4711%      233659358
Error Rate:        17.6951%      307195     4.3842%       10729991
Sub Rate:          17.4071%      302196     0.4166%        1019532
Del Rate:           0.5601%        9723     3.9416%        9646883
Ins Rate:           0.5008%        8694     0.0260%          63576
N Rate:             0.8424%       14625     0.1447%         354257


Read 2 data:        pct reads num reads   pct bases    num bases

mapped:            99.0163%     1731025    98.9932%      234418960
unambiguous:       98.6658%     1724898    98.6505%      233607294
ambiguous:          0.3505%        6127     0.3428%         811666
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   79.7419%     1394065    79.0239%      187130913
semiperfect site:  80.4516%     1406472    79.7542%      188860289
rescued:            0.4903%        8572

Match Rate:             NA         NA    95.5730%      232674914
Error Rate:        18.8142%      325678     4.2809%       10422066
Sub Rate:          18.5298%      320756     0.5431%        1322187
Del Rate:           0.5678%        9829     3.7106%        9033592
Ins Rate:           0.5001%        8656     0.0272%          66287
N Rate:             0.8515%       14739     0.1461%         355572

Reads:                                3496444
Mapped reads:                         3465951
Mapped bases:                         472817321
Ref scaffolds:                        4301
Ref bases:                            9123063

Percent mapped:                       99.128
Percent proper pairs:                 97.848
Average coverage:                     51.827
Average coverage with deletions:      51.944
Standard deviation:                     63.840
Percent scaffolds with any coverage:  98.28
Percent of reference bases covered:   99.87

Total time:       825.853 seconds.

#assemble the reads with megahit
#tutorial: https://sites.google.com/site/wiki4metagenomics/tools/assembly/megahit
module load python
module load megahit/1.0.6.1
#megahit on bbduk trimmed reads yields 1151 contigs 
megahit --continue --12 S_denitrificans_qtrimmed.fq.gz -t 12 -o S_denitrificans_qtrimmed_megahit --min-contig-len 1000

#try megahit assembly on trimmomatic trimmed reads  - this produces 682 contigs and 682 scaffolds
~/bbmap/reformat.sh in1=S_denitrificans_forward_paired.fq.gz in2=S_denitrificans_reverse_paired.fq.gz out=S_denitrificans_interleaved_trimmomatic.fq
megahit --continue --12 S_denitrificans_interleaved_trimmomatic.fq -t 12 -o S_denitrificans_trimmomatic_megahit --min-contig-len 1000

#map reads and calculate stats 
#can calcuate per gene coverage in R with covstats file
#hist file gives you # of bases per coverage value 
module load samtools/1.6

~/bbmap/bbmap.sh in=S_denitrificans_qtrimmed.fq.gz ref=S_denitrificans_qtrimmed_megahit/final.contigs.fa covstats=megahit_covstats.txt outm=S_denitrificans_qtrimmed_megahit_mapped.bam minid=0.95 covhist=megahit_covhist.txt

   ------------------   Results   ------------------

Genome:                 1
Key Length:             13
Max Indel:              16000
Minimum Score Ratio:    0.56
Mapping Mode:           normal
Reads Used:             3496444 (473542180 bases)

Mapping:            484.653 seconds.
Reads/sec:        7214.33
kBases/sec:       977.08


Pairing data:     pct pairs num pairs   pct bases    num bases

mated pairs:       94.7614%     1656640    94.6501%      448207990
bad pairs:          0.3137%        5485     0.3427%        1622934
insert size avg:    218.72


Read 1 data:        pct reads num reads   pct bases    num bases

mapped:            95.7198%     1673395    95.6612%      226467564
unambiguous:       95.5681%     1670742    95.5315%      226160565
ambiguous:          0.1518%        2653     0.1297%         306999
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   77.9337%     1362454    77.3506%      183119084
semiperfect site:  78.4382%     1371273    77.8581%      184320595
rescued:            0.4292%        7504

Match Rate:             NA         NA    98.9419%      225022718
Error Rate:        17.9922%      302785     0.9315%        2118442
Sub Rate:          17.7265%      298313     0.4868%        1107204
Del Rate:           0.4862%        8182     0.4228%         961557
Ins Rate:           0.4362%        7340     0.0218%          49681
N Rate:             0.6468%       10885     0.1266%         287961


Read 2 data:        pct reads num reads   pct bases    num bases

mapped:            95.5098%     1669724    95.4323%      225986674
unambiguous:       95.3559%     1667032    95.3005%      225674549
ambiguous:          0.1540%        2692     0.1318%         312125
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   76.6607%     1340200    75.9687%      179896255
semiperfect site:  77.1583%     1348899    76.4691%      181081200
rescued:            0.4599%        8040

Match Rate:             NA         NA    98.7812%      224230754
Error Rate:        19.1593%      321471     1.0920%        2478712
Sub Rate:          18.8970%      317070     0.6222%        1412470
Del Rate:           0.4959%        8320     0.4453%        1010821
Ins Rate:           0.4484%        7523     0.0244%          55421
N Rate:             0.6535%       10965     0.1269%         288029

Reads:                                3496444
Mapped reads:                         3343119
Mapped bases:                         455797357
Ref scaffolds:                        1151
Ref bases:                            7984282

Percent mapped:                       95.615
Percent proper pairs:                 94.761
Average coverage:                     57.087
Average coverage with deletions:      56.830
Standard deviation:                     53.769
Percent scaffolds with any coverage:  100.00
Percent of reference bases covered:   99.98

Total time:       500.561 seconds.

#try map reads from trimmomatic trimmed reads
~/bbmap/bbmap.sh in=S_denitrificans_interleaved_trimmomatic.fq ref=S_denitrificans_trimmomatic_megahit/final.contigs.fa covstats=megahit_trimmomatic_covstats.txt outm=S_denitrificans_megahit_trimmomatic_mapped.bam minid=0.95 covhist=megahit_trimmomatic_covhist.txt

   ------------------   Results   ------------------

Genome:                 1
Key Length:             13
Max Indel:              16000
Minimum Score Ratio:    0.56
Mapping Mode:           normal
Reads Used:             3372328 (450798092 bases)

Mapping:            466.352 seconds.
Reads/sec:        7231.29
kBases/sec:       966.65


Pairing data:     pct pairs num pairs   pct bases    num bases

mated pairs:       95.8185%     1615657    95.7811%      431779356
bad pairs:          0.3406%        5743     0.3591%        1618826
insert size avg:    218.80


Read 1 data:        pct reads num reads   pct bases    num bases

mapped:            96.4887%     1626957    96.4736%      217472765
unambiguous:       96.2497%     1622927    96.2599%      216991239
ambiguous:          0.2390%        4030     0.2136%         481526
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   82.5237%     1391485    82.5587%      186105645
semiperfect site:  83.0237%     1399915    83.0626%      187241420
rescued:            0.3428%        5781

Match Rate:             NA         NA    99.1423%      216577688
Error Rate:        13.8915%      226939     0.7383%        1612881
Sub Rate:          13.6065%      222284     0.2732%         596725
Del Rate:           0.4281%        6994     0.4480%         978631
Ins Rate:           0.3206%        5238     0.0172%          37525
N Rate:             0.6469%       10568     0.1194%         260827


Read 2 data:        pct reads num reads   pct bases    num bases

mapped:            96.4385%     1626111    96.4276%      217324601
unambiguous:       96.2019%     1622121    96.2143%      216843813
ambiguous:          0.2366%        3990     0.2133%         480788
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   81.4967%     1374168    81.5183%      183722592
semiperfect site:  81.9930%     1382536    82.0190%      184851079
rescued:            0.4231%        7134

Match Rate:             NA         NA    99.0831%      216292139
Error Rate:        14.9406%      243958     0.7984%        1742935
Sub Rate:          14.6632%      239428     0.3301%         720581
Del Rate:           0.4520%        7380     0.4439%         968973
Ins Rate:           0.3872%        6323     0.0245%          53381
N Rate:             0.6329%       10335     0.1184%         258500

Reads:                                3372328
Mapped reads:                         3253068
Mapped bases:                         438050434
Ref scaffolds:                        682
Ref bases:                            8164169

Percent mapped:                       96.464
Percent proper pairs:                 95.818
Average coverage:                     53.655
Average coverage with deletions:      53.421
Standard deviation:                     49.802
Percent scaffolds with any coverage:  100.00
Percent of reference bases covered:   99.83

Total time:       480.254 seconds.

# calculate assembly statistics - added 
~/bbmap/statswrapper.sh S_denitrificans_spades/*.fasta S_denitrificans_spades_careful/*.fasta tadpole_contigs.fasta S_denitrificans_qtrimmed_megahit/*.fa S_denitrificans_trimmomatic_megahit/*.fa mincontig1000_noHC/megahit_assembly_1000/final.contigs.fa  final.contigs.fa.metabat-bins/*.fa > S_denitrificans_stats.txt


#bin genomes with metabat
#tutorial: https://bitbucket.org/berkeleylab/metabat/src/master/
#http://www.htslib.org/doc/samtools-sort.html
module load metabat/0.32.4
module load anaconda3/2018.12
source activate metabat  

samtools sort -o S_denitrificans_megahit_trimmomatic_mapped_sorted.bam S_denitrificans_megahit_trimmomatic_mapped.bam
runMetaBat.sh S_denitrificans_trimmomatic_megahit/final.contigs.fa S_denitrificans_megahit_trimmomatic_mapped_sorted.bam

###output###
Output depth matrix to final.contigs.fa.depth.txt
Output pairedContigs lower triangle to final.contigs.fa.paired.txt
minContigLength: 1000
minContigDepth: 1
Output matrix to final.contigs.fa.depth.txt
Opening 1 bams
Consolidating headers
Allocating pairedContigs matrix: 0 MB over 1 threads
Processing bam files
Thread 0 finished: S_denitrificans_megahit_trimmomatic_mapped_sorted.bam with 3263336 reads and 3171512 readsWellMapped
Creating depth matrix file: final.contigs.fa.depth.txt
Closing most bam files
Creating pairedContigs matrix file: final.contigs.fa.paired.txt
Closing last bam file
Finished
Finished jgi_summarize_bam_contig_depths at Mon Sep 14 16:23:08 CDT 2020
Creating depth file for metabat at Mon Sep 14 16:23:08 CDT 2020
Executing: 'metabat2  --inFile S_denitrificans_trimmomatic_megahit/final.contigs.fa --outFile final.contigs.fa.metabat-bins/bin --abdFile final.contigs.fa.depth.txt' at Mon Sep 14 16:23:08 CDT 2020
MetaBAT 2 (v2.12.1) using minContig 2500, minCV 1.0, minCVSum 1.0, maxP 95%, minS 60, and maxEdges 200.
2 bins (7393637 bases in total) formed.
Finished metabat2 at Mon Sep 14 16:23:11 CDT 2020
###output###

#bin1 = 221 contigs, bin2 = 276 contigs

#CheckM
#overview of output: https://github.com/Ecogenomics/CheckM/wiki/Reported-Statistics
module load python 
module load checkm/1.0.7
module load samtools/1.6

#get completeness, contamination, and putative lineage with CheckM
checkm lineage_wf --tab_table -t 8 -x fa final.contigs.fa.metabat-bins checkm_out_megahit_trimmomatic_refined

Bin Id  Marker lineage  # genomes # markers # marker sets 0 1 2 3 4 5+  Completeness  Contamination Strain heterogeneity
bin.1 c__Betaproteobacteria (UID3959) 235 419 211 22  388 9 0 0 0 94.76 2.44  33.33
bin.2 o__Rhizobiales (UID3642)  107 485 316 52  423 10  0 0 0 96.89 2.06  70.00



#map reads in each bin from trimmomatic trimmed reads
~/bbmap/bbmap.sh in=S_denitrificans_interleaved_trimmomatic.fq ref=final.contigs.fa.metabat-bins/bin.1.fa covstats=megahit_trimmomatic_covstats_bin1.txt minid=0.95 covhist=megahit_trimmomatic_covhist_bin1.txt

   ------------------   Results   ------------------

Genome:                 1
Key Length:             13
Max Indel:              16000
Minimum Score Ratio:    0.56
Mapping Mode:           normal
Reads Used:             3372328 (450798092 bases)

Mapping:            550.021 seconds.
Reads/sec:        6131.27
kBases/sec:       819.60


Pairing data:     pct pairs num pairs   pct bases    num bases

mated pairs:       59.5363%     1003879    59.4359%      267936104
bad pairs:          0.1324%        2233     0.1395%         628708
insert size avg:    215.07


Read 1 data:        pct reads num reads   pct bases    num bases

mapped:            59.8849%     1009758    59.7942%      134789388
unambiguous:       59.7084%     1006781    59.6432%      134448964
ambiguous:          0.1766%        2977     0.1510%         340424
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   51.5265%      868821    51.4741%      116033993
semiperfect site:  51.8785%      874756    51.8213%      116816732
rescued:            0.2574%        4340

Match Rate:             NA         NA    96.9340%      134066530
Error Rate:        13.2651%      134937     2.9083%        4022407
Sub Rate:          12.9592%      131826     0.3418%         472800
Del Rate:           0.5110%        5198     2.5434%        3517687
Ins Rate:           0.4206%        4279     0.0231%          31920
N Rate:             0.7843%        7978     0.1577%         218138


Read 2 data:        pct reads num reads   pct bases    num bases

mapped:            59.8601%     1009340    59.7182%      134590531
unambiguous:       59.6839%     1006368    59.5668%      134249256
ambiguous:          0.1763%        2972     0.1514%         341275
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   50.7214%      855246    50.6231%      114092228
semiperfect site:  51.0670%      861074    50.9648%      114862363
rescued:            0.2855%        4814

Match Rate:             NA         NA    96.5576%      133778567
Error Rate:        14.6016%      148467     3.2871%        4554211
Sub Rate:          14.3074%      145476     0.4002%         554532
Del Rate:           0.5339%        5429     2.8563%        3957403
Ins Rate:           0.4841%        4922     0.0305%          42276
N Rate:             0.7703%        7832     0.1553%         215156

Reads:                                3372328
Mapped reads:                         2018788
Mapped bases:                         271355652
Ref scaffolds:                        221
Ref bases:                            2758518

Percent mapped:                       59.863
Percent proper pairs:                 59.527
Average coverage:                     98.370
Average coverage with deletions:      98.460
Standard deviation:                     52.716
Percent scaffolds with any coverage:  100.00
Percent of reference bases covered:   100.00


#could argue that this was introduced during extraction/sequencing 
~/bbmap/bbmap.sh in=S_denitrificans_interleaved_trimmomatic.fq ref=final.contigs.fa.metabat-bins/bin.2.fa covstats=megahit_trimmomatic_covstats_bin2.txt minid=0.95 covhist=megahit_trimmomatic_covhist_bin2.txt

   ------------------   Results   ------------------

Genome:                 1
Key Length:             13
Max Indel:              16000
Minimum Score Ratio:    0.56
Mapping Mode:           normal
Reads Used:             3372328 (450798092 bases)

Mapping:            507.324 seconds.
Reads/sec:        6647.29
kBases/sec:       888.58


Pairing data:     pct pairs num pairs   pct bases    num bases

mated pairs:       21.9513%      370135    21.9942%       99149528
bad pairs:          0.0428%         721     0.0427%         192556
insert size avg:    233.12


Read 1 data:        pct reads num reads   pct bases    num bases

mapped:            22.0355%      371555    22.0760%       49764113
unambiguous:       21.9523%      370152    21.9937%       49578578
ambiguous:          0.0832%        1403     0.0823%         185535
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   17.7592%      299450    17.8619%       40264686
semiperfect site:  17.7859%      299899    17.8885%       40324653
rescued:            0.1254%        2114

Match Rate:             NA         NA    98.9207%       49466618
Error Rate:        19.0986%       71519     1.0479%         524013
Sub Rate:          18.8612%       70630     0.5469%         273477
Del Rate:           0.4291%        1607     0.4844%         242230
Ins Rate:           0.3851%        1442     0.0166%           8306
N Rate:             0.2043%         765     0.0314%          15712


Read 2 data:        pct reads num reads   pct bases    num bases

mapped:            22.0212%      371314    22.1340%       49884655
unambiguous:       21.9386%      369921    22.0518%       49699375
ambiguous:          0.0826%        1393     0.0822%         185280
low-Q discards:     0.0000%           0     0.0000%              0

perfect best site:   17.7493%      299283    17.8968%       40335038
semiperfect site:  17.7744%      299706    17.9220%       40391789
rescued:            0.1711%        2885

Match Rate:             NA         NA    98.8436%       49565821
Error Rate:        19.0806%       71537     1.1257%         564477
Sub Rate:          18.8408%       70638     0.5819%         291777
Del Rate:           0.4580%        1717     0.5206%         261059
Ins Rate:           0.4382%        1643     0.0232%          11641
N Rate:             0.1896%         711     0.0307%          15416

Reads:                                3372328
Mapped reads:                         742849
Mapped bases:                         100388903
Ref scaffolds:                        276
Ref bases:                            4635119

Percent mapped:                       22.028
Percent proper pairs:                 21.951
Average coverage:                     21.658
Average coverage with deletions:      21.558
Standard deviation:                     9.765
Percent scaffolds with any coverage:  100.00
Percent of reference bases covered:   99.71
#run ssu finder
#avg nucleotide + amino acid identity test 


#run checkM SSU finder
mkdir ssu_finder 
for file in *.fa; do checkm ssu_finder -x .fa ${file} ./ ./ssu_finder/${file} ; done
for file in ssu_finder/*/ssu.fna; do cat $file; done > ssu_finder/all_ssu.fna


#annotate ORFs from metabolic output with Fegenie

module load python 
source activate fegenie

/home/cpc7770/FeGenie/FeGenie.py -bin_dir ORFs -bin_ext faa -out fegenie_output --orfs



