#!/bin/bash

# Directory containing fasta files
dir="/home/ericgdp/wolbspir/fastas"

# Output directory
out_dir="/home/ericgdp/wolbspir/blastX"

# Loop over all fasta files in directory
for fasta_file in $dir/*.fasta
do
  # Get the base name of the file (without extension)
  base_name=$(basename $fasta_file .fasta)

  # Run BLAST command. Modify this according to your specific BLAST command.
  blastx -query $fasta_file -db /data/databases/blastdb_08032023/nr/nr -out $out_dir/$base_name"_blast_results.tsv" -outfmt '6 qseqid sseqid qlen slen pident evalue bitscore stitle' -num_threads 20  -max_target_seqs '1'
done

