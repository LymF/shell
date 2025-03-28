#!/bin/bash

# Diretório onde estão as pastas contendo os arquivos scaffolds.fasta
input_dir="/home/lucas/montagem/virophage"

# Diretório onde você quer salvar os arquivos renomeados
output_dir="/home/lucas/montagem/fastas/virophage"

# Loop sobre todas as pastas no diretório de entrada
for pasta in "$input_dir"/*/; do
    # Extrair o nome da pasta
    nome_pasta=$(basename "$pasta")

    # Verificar se o arquivo scaffolds.fasta está presente
    if [ -e "$pasta/scaffolds.fasta" ]; then
        # Renomear o arquivo para o nome da pasta
        mv "$pasta/scaffolds.fasta" "$output_dir/$nome_pasta.fasta"
        echo "Arquivo renomeado e movido para $output_dir/$nome_pasta.fasta"
    else
        echo "Arquivo scaffolds.fasta não encontrado em $pasta"
    fi
done
