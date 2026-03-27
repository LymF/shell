#!/bin/bash

# Diretório contendo os arquivos CAP3 contigs
input_dir="/home/ericgdp/wolbspir/fastadali/fastasdodiamond"

# Diretório de saída para os resultados do CD-HIT
output_dir="/home/ericgdp/wolbspir/fastadali/fastasdodiamond/cd_hit_output"

# Certifique-se de que o diretório de saída exista, se não, crie-o
mkdir -p "$output_dir"

# Iterar sobre todos os arquivos CAP3 contigs no diretório de entrada
for cap3_contigs_file in "$input_dir"/*.cap.contigs; do
    if [ -f "$cap3_contigs_file" ]; then
        # Extrair o nome do arquivo sem a extensão
        filename=$(basename -- "$cap3_contigs_file")
        filename_noext="${filename%.*}"

        # Arquivo temporário em formato FASTA
        temp_fasta="$output_dir/$filename_noext.fasta"

        # Converter para formato FASTA usando seqtk
        seqtk seq -A "$cap3_contigs_file" > "$temp_fasta"

        # Caminho para o arquivo de saída do CD-HIT
        cd_hit_output="$output_dir/$filename_noext.cdhit"

        # Executar o CD-HIT
        cd-hit -i "$temp_fasta" -o "$cd_hit_output" -c 0.95 -n 5 -M 8000 -d 0

        echo "CD-HIT concluído para $filename. Resultado salvo em $cd_hit_output"
        # Remover o arquivo temporário
        rm "$temp_fasta"
    fi
done

echo "Todos os processamentos CD-HIT concluídos!"

