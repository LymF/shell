#!/bin/bash

# Diretório onde estão os arquivos fasta
input_dir="/home/lucasyago/mimivirus/fastas/virophage"

# Diretório do banco de dados NT
db_dir="/home/common/nt/nt"

# Loop sobre todos os arquivos fasta no diretório de entrada
for fasta_file in "$input_dir"/*.fasta; do
    # Nome do arquivo sem extensão
    filename=$(basename -- "$fasta_file")
    filename_no_ext="${filename%.*}"

    # Rodar o blastn no arquivo fasta e salvar o resultado
    blastn -query "$fasta_file" -db "$db_dir" -out "$input_dir/$filename_no_ext.blastn_results.txt" -num_threads "30" -outfmt "6 qseqid sseqid qcovs pident length evalue bitscore stitle" -max_target_seqs "1"

    echo "Blastn concluído para o arquivo $fasta_file"
done
