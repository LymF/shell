#!/bin/bash

# Diretório contendo os arquivos tabulares
input_dir="/mnt/c/Users/Lucas Melo/Downloads/Daliane/diamond/"

# Loop sobre todos os arquivos no diretório que correspondem ao padrão "*.tabular"
for input_file in "$input_dir"/*.tabular; do
    # Verificar se há arquivos correspondentes
    if [ -e "$input_file" ]; then
        # Extrair o nome do arquivo sem a extensão
        filename=$(basename -- "$input_file")
        filename_noext="${filename%.*}"

        # Nome do arquivo de saída para o resultado do grep
        output_file="$input_dir/${filename_noext}_filtered.tsv"

        # Executar o grep no arquivo tabular
        grep -iv 'RNA-dependent DNA polymerase' "$input_file" | grep -iE 'RdRp|capsid|coat|replicase|glycoprotein|nucleoprotein|nucleocapsid' > "$output_file"

        # Verificar se a execução foi bem-sucedida antes de imprimir a mensagem
        if [ $? -eq 0 ]; then
            echo "Grep concluído para $input_file. Resultado salvo em $output_file"
        else
            echo "Erro ao executar Grep para $input_file"
        fi
    fi
done

echo "Todos os processamentos Grep concluídos!"
