#!/bin/bash

# Set memory and threads parameters
THREADS=20
MEMORY=20G  # 20 GB for tools that accept GB
MEMORY_MB=20000  # 20 GB in MB for tools that require MB input

# Define paths to necessary files and tools
bowtie2_index="/home/lucasyago/Ande"
diamond_db="/home/lucasyago/rhodnius/diamonddb/viraldb"  # Replace with the path to your Diamond database

# Directory containing the paired-end FASTQ files
fastq_dir="/home/lucasyago/rhodnius/fastqs"  # Change to the directory where your FASTQ files are located
output_dir="/home/lucasyago/rhodnius/output"  # Directory to store all outputs

# Create output directories
mkdir -p "$output_dir/trimmed"
mkdir -p "$output_dir/qc"
mkdir -p "$output_dir/mapping"
mkdir -p "$output_dir/assembly"
mkdir -p "$output_dir/contig_processing"
mkdir -p "$output_dir/blast_results"

# Loop over all paired-end FASTQ files
for fastq1 in "$fastq_dir"/*_1.fastq.gz; do
    samp=$(basename "$fastq1" "_1.fastq.gz")
    fastq2="${fastq_dir}/${samp}_2.fastq.gz"
    
    # Quality control and trimming using FastP
    fastp -i "$fastq1" -I "$fastq2" -o "$output_dir/trimmed/${samp}_trimmed_R1.fastq.gz" \
          -O "$output_dir/trimmed/${samp}_trimmed_R2.fastq.gz" -h "$output_dir/qc/${samp}_fastp.html" \
          -j "$output_dir/qc/${samp}_fastp.json" -w $THREADS
    
    trimmed_fastq1="$output_dir/trimmed/${samp}_trimmed_R1.fastq.gz"
    trimmed_fastq2="$output_dir/trimmed/${samp}_trimmed_R2.fastq.gz"
    
    # Run Bowtie2 for host alignment, extracting unaligned reads
    genome_dirname=$(basename "$bowtie2_index")
    bowtie2 -x "$bowtie2_index" -1 "$trimmed_fastq1" -2 "$trimmed_fastq2" -S "$output_dir/mapping/${genome_dirname}_${samp}.sam" \
        --threads $THREADS 2>&1 | tee "$output_dir/mapping/${samp}_mapping_summary.txt"
    
    # Convert SAM to BAM
    samtools view -bS "$output_dir/mapping/${genome_dirname}_${samp}.sam" > "$output_dir/mapping/${genome_dirname}_${samp}.bam"
    
    # Remove the SAM file to save space
    rm "$output_dir/mapping/${genome_dirname}_${samp}.sam"
    
    # Extract unaligned reads
    samtools view -b -f 12 -F 256 "$output_dir/mapping/${genome_dirname}_${samp}.bam" > "$output_dir/mapping/${genome_dirname}_${samp}_bothReadsUnmapped.bam"
    
    # Remove the original BAM file to save space
    rm "$output_dir/mapping/${genome_dirname}_${samp}.bam"
    
    # Sort BAM by name
    samtools sort -n -m 5G -@ 2 "$output_dir/mapping/${genome_dirname}_${samp}_bothReadsUnmapped.bam" -o "$output_dir/mapping/${genome_dirname}_${samp}_bothReadsUnmapped_sorted.bam"
    
    # Remove unsorted BAM to save space
    rm "$output_dir/mapping/${genome_dirname}_${samp}_bothReadsUnmapped.bam"
    
    # Convert BAM to FASTQ
    samtools fastq -@ $THREADS "$output_dir/mapping/${genome_dirname}_${samp}_bothReadsUnmapped_sorted.bam" \
        -1 "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R1.fastq.gz" \
        -2 "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R2.fastq.gz" -0 /dev/null -s /dev/null -n
    
    # Remove the sorted BAM to save space
    rm "$output_dir/mapping/${genome_dirname}_${samp}_bothReadsUnmapped_sorted.bam"
    
    # Assembly using SPAdes
    spades.py --pe1-1 "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R1.fastq.gz" \
              --pe1-2 "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R2.fastq.gz" \
              -o "$output_dir/assembly/spades_$samp" -t $THREADS -m $MEMORY_MB
    
    # Assembly using RNA-Viral SPAdes
    spades.py --rnaviral --pe1-1 "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R1.fastq.gz" \
              --pe1-2 "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R2.fastq.gz" \
              -o "$output_dir/assembly/rnaviral_spades_$samp" -t $THREADS -m $MEMORY_MB
    
    # Assembly using Trans-ABySS
    transabyss --pe "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R1.fastq.gz" "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R2.fastq.gz" \
               --outdir "$output_dir/assembly/transabyss_$samp" --threads $THREADS 

    # Prepare input for IDBA: concatenate and convert FASTQ to FASTA
    zcat "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R1.fastq.gz" "$output_dir/mapping/${genome_dirname}_${samp}_host_removed_R2.fastq.gz" \
        > "$output_dir/mapping/${genome_dirname}_${samp}_combined.fastq"
    
    fq2fa --merge --filter "$output_dir/mapping/${genome_dirname}_${samp}_combined.fastq" "$output_dir/mapping/${genome_dirname}_${samp}_combined.fa"
    
    # Assembly using IDBA
    idba_ud -r "$output_dir/mapping/${genome_dirname}_${samp}_combined.fa" -o "$output_dir/assembly/idba_$samp" --num_threads $THREADS --mink 20 --maxk 120 --step 20
    
    # Combine all contigs into a single file
    cat "$output_dir/assembly/spades_$samp/contigs.fasta" "$output_dir/assembly/rnaviral_spades_$samp/contigs.fasta" \
        "$output_dir/assembly/transabyss_$samp/transabyss-final.fa" "$output_dir/assembly/idba_$samp/contig.fa" \
        > "$output_dir/contig_processing/${samp}_all_contigs.fasta"
    
    # Run CAP3 on all contigs and singlets
    cap3 "$output_dir/contig_processing/${samp}_all_contigs.fasta" > "$output_dir/contig_processing/${samp}_cap3.log"
    
    # Combine the singlets and contigs from CAP3 output
    cat "$output_dir/contig_processing/${samp}_all_contigs.fasta.cap.contigs" "$output_dir/contig_processing/${samp}_all_contigs.fasta.cap.singlets" \
        > "$output_dir/contig_processing/${samp}_cap3_combined.fasta"
    
    # Run CD-HIT on CAP3 output
    cd-hit-est -i "$output_dir/contig_processing/${samp}_cap3_combined.fasta" -o "$output_dir/contig_processing/${samp}_cdhit_out.fasta" -c 0.99 -n 10 -M $MEMORY_MB -T $THREADS
    
    # Run Diamond BLASTx against the viral RefSeq database
    diamond blastx -d "$diamond_db" -q "$output_dir/contig_processing/${samp}_cdhit_out.fasta" \
        --outfmt '6 qseqid sseqid qlen slen pident evalue bitscore stitle full_qseq' \
        --max-target-seqs 1 --out "$output_dir/blast_results/${samp}_diamond_output.tsv" --threads $THREADS
done

echo "Pipeline completed successfully."
