#!/bin/bash

# Diretório contendo os arquivos CAP3 contigs
input_dir="/home/lucas/fastasdodiamond/fastasdodiamond"

# Diretório de saída para os arquivos FASTA
output_dir="/home/lucas/fastasdodiamond/fastasdodiamond/cap3fasta"

# Certifique-se de que o diretório de saída exista, se não, crie-o
mkdir -p "$output_dir"

# Iterar sobre todos os arquivos CAP3 contigs no diretório de entrada
for cap3_contigs_file in "$input_dir"/*.cap.contigs; do
    if [ -f "$cap3_contigs_file" ]; then
        # Extrair o nome do arquivo sem a extensão
        filename=$(basename -- "$cap3_contigs_file")
        filename_noext="${filename%.*}"

        # Caminho para o arquivo de saída no formato FASTA
        fasta_output="$output_dir/$filename_noext.fasta"

        # Converter para formato FASTA usando seqtk
        seqtk seq -A "$cap3_contigs_file" > "$fasta_output"

        echo "Conversão concluída para $filename. Resultado salvo em $fasta_output"
    fi
done

echo "Todos os processamentos de conversão para FASTA concluídos!"
