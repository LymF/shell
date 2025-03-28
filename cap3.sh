#!/bin/bash

# Diretório contendo os arquivos FASTA
input_dir="/home/ericgdp/wolbspir/fastadali/fastasdodiamond"

# Diretório de saída para os resultados do CAP3
output_dir="/home/ericgdp/wolbspir/cap3_output"

# Certifique-se de que o diretório de saída exista, se não, crie-o
mkdir -p "$output_dir"

# Iterar sobre todos os arquivos FASTA no diretório de entrada
for fasta_file in "$input_dir"/*.fasta; do
    if [ -f "$fasta_file" ]; then
        # Extrair o nome do arquivo sem a extensão
        filename=$(basename -- "$fasta_file")
        filename_noext="${filename%.*}"

        # Caminho para o arquivo de saída do CAP3
        cap3_output="$output_dir/$filename_noext.cap"

        # Executar o CAP3
        cap3 "$fasta_file" > "$cap3_output"

        echo "CAP3 concluído para $filename. Resultado salvo em $cap3_output"
    fi
done

echo "Todos os processamentos CAP3 concluídos!"
