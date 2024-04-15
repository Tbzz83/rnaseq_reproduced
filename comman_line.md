## Obtaining the raw data
```bash
URL=http://data.biostarhandbook.com/rnaseq/projects/griffith/griffith-data.tar.gz

wget -nc $URL

tar zxvf griffith-data.tar.gz
```
*This gives us a reads folder and a refs folder which contains our reference genome (just chromosome 22) and a .gtf file as well*

#### creating a transcript file from .gtf file
```bash
gffread -w refs/transcripts.fa -g refs/22.fa refs/22.gtf
```
#### using design.csv we can create a txt file called ids.txt to short hand our samples
```bash
cat design.csv | csvcut -c sample | sed 1d > ids.txt
```
## We will do both alignment based and classification based RNA-seq. 
#### Alignment based
```bash
IDX=refs/22.fa

hisat2-build $IDX $IDX

samtools faidx $IDX
```
*we'll make a directory for our bam files and automate through all the reads using ids.txt*
```bash
mkdir -p bam

cat ids.txt | parallel "hisat2 -x $IDX -1 reads/{}_R1.fq -2 reads/{}_R2.fq | samtools sort > bam/{}.bam"

cat ids.txt | parallel "samtools index bam/{}.bam"
```
*Making a bigWig for easier visualize in IGV if needed*
```bash
cat ids.txt | parallel "bedtools genomecov -ibam  bam/{}.bam -split -bg  > bam/{}.bg"

cat ids.txt | parallel "bedGraphToBigWig bam/{}.bg  ${IDX}.fai bam/{}.bw"

cat ids.txt | parallel -j 1 echo "bam/{}.bam" | \
    xargs featureCounts -p --countReadPairs -a refs/features.gff -o counts.txt
```
*This gives us a counts.txt file which we will convert to a simpler .csv*
```bash
Rscript ~/rcode/code/parse_featurecounts.r
```

#### Classification based
```bash
REF=refs/transcripts.fa

IDX=idx/salmon.idx

salmon index -t ${REF} -i ${IDX}

mkdir -p salmon

cat ids.txt | parallel -j 4 "salmon quant -i ${IDX} -l A --validateMappings -1 reads/{}_R1.fq -2 reads/{}_R2.fq  -o salmon/{}"
```

*We now have a directory called salmon in which each of our samples has transcripts quantified for them*
```bash
Rscript ~/rcode/code/combine_transcripts.r
```
*this takes all our quant.sf files and combines them into counts.csv - similar to the alignment based method. Both should produce similar results*

#### Running Deseq2 on either counts.csv files
```bash
Rscript ~/rcode/code/deseq2.Rr

Rscript ~/rcode/code/create_heatmap.r
```
*create_heatmap works using deseq2 and creates the following visualization*





