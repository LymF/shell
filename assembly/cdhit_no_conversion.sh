#!/bin/bash

# Diretório contendo os arquivos FASTA
input_dir="/home/lucas/fastasdodiamond/fastasdodiamond"

# Diretório de saída para os resultados do CD-HIT
output_dir="/home/lucas/fastasdodiamond/fastasdodiamond/cd_hit_output"

# Certifique-se de que o diretório de saída exista, se não, crie-o
mkdir -p "$output_dir"

# Iterar sobre todos os arquivos FASTA no diretório de entrada
for fasta_file in "$input_dir"/*.fasta; do
    if [ -f "$fasta_file" ]; then
        # Extrair o nome do arquivo sem a extensão
        filename=$(basename -- "$fasta_file")
        filename_noext="${filename%.*}"

        # Caminho para o arquivo de saída do CD-HIT em formato FASTA
        cd_hit_output="$output_dir/$filename_noext.cdhit.fasta"

        # Executar o CD-HIT
        cd-hit -i "$fasta_file" -o "$cd_hit_output" -c 0.95 -n 5 -M 8000 -d 0

        echo "CD-HIT concluído para $filename. Resultado salvo em $cd_hit_output"
    fi
done

echo "Todos os processamentos CD-HIT concluídos!"
