#!/bin/bash

# Set memory and threads parameters
THREADS=20
MEMORY=20G  # 20 GB for tools that accept GB
MEMORY_MB=20000  # 20 GB in MB for tools that require MB input

# Define paths to necessary files and tools
diamond_db="/home/lucasyago/viraldb"  # Replace with the path to your Diamond database

# Directory containing the processed paired-end FASTQ files (already host-removed)
fastq_dir="/home/lucasyago/anderson"  # Change to the directory with your preprocessed FASTQ files
output_dir="/home/lucasyago/anderson/output"  # Directory to store all outputs

# Create output directories
mkdir -p "$output_dir/assembly"
mkdir -p "$output_dir/contig_processing"
mkdir -p "$output_dir/blast_results"

# Loop over all paired-end FASTQ files
for fastq1 in "$fastq_dir"/*_1.fastq.gz; do
    samp=$(basename "$fastq1" "_1.fastq.gz")
    fastq2="${fastq_dir}/${samp}_2.fastq.gz"

    # Assembly using RNA SPAdes
    spades.py --rnaviral --pe1-1 "$fastq1" --pe1-2 "$fastq2" \
              -o "$output_dir/assembly/rnaviral_spades_$samp" -t $THREADS -m $MEMORY_MB

    # Assembly using Trinity
    Trinity --seqType fq --left "$fastq1" --right "$fastq2" --max_memory $MEMORY --CPU $THREADS \
            --output "$output_dir/assembly/trinity_$samp"

    # Assembly using MEGAHIT
    megahit -1 "$fastq1" -2 "$fastq2" -o "$output_dir/assembly/megahit_$samp" --num-cpu-threads $THREADS --mem-flag $MEMORY_MB

    # Combine all contigs into a single file
    cat "$output_dir/assembly/rnaviral_spades_$samp/contigs.fasta" \
        "$output_dir/assembly/trinity_$samp/Trinity.fasta" \
        "$output_dir/assembly/megahit_$samp/final.contigs.fa" \
        > "$output_dir/contig_processing/${samp}_all_contigs.fasta"

    # Run CAP3 on all contigs and singlets
    cap3 "$output_dir/contig_processing/${samp}_all_contigs.fasta" > "$output_dir/contig_processing/${samp}_cap3.log"

    # Combine the singlets and contigs from CAP3 output
    cat "$output_dir/contig_processing/${samp}_all_contigs.fasta.cap.contigs" \
        "$output_dir/contig_processing/${samp}_all_contigs.fasta.cap.singlets" \
        > "$output_dir/contig_processing/${samp}_cap3_combined.fasta"

    # Run CD-HIT on CAP3 output
    cd-hit-est -i "$output_dir/contig_processing/${samp}_cap3_combined.fasta" \
               -o "$output_dir/contig_processing/${samp}_cdhit_out.fasta" -c 0.99 -n 10 -M $MEMORY_MB -T $THREADS

    # Run Diamond BLASTx against the viral RefSeq database
    diamond blastx -d "$diamond_db" -q "$output_dir/contig_processing/${samp}_cdhit_out.fasta" \
        --outfmt '6 qseqid sseqid qlen slen pident evalue bitscore stitle full_qseq' \
        --max-target-seqs 1 --out "$output_dir/blast_results/${samp}_diamond_output.tsv" --threads $THREADS
done

echo "Pipeline completed successfully."
