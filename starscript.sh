#!/bin/bash

# Criar um novo diretório
dir_name="allgenomesunmapped"
mkdir -p "$dir_name"

# Obter o caminho completo para a pasta fastp/
pasta_fastq="/home/ericgdp/lucas/mimivirus/fastq"

# Iterar sobre os arquivos encontrados na pasta fastp/
for arquivo in "$pasta_fastq"/*_R1.fastq.gz; do
    # Verificar se o arquivo tem o padrão correto de nome (_R1.fastq.gz)
    if [[ -f "$arquivo" ]]; then
        # Extrair o nome do arquivo (sem extensão) e sem o sufixo _R1
        samp=$(basename "$arquivo" _R1.fastq.gz)

        # Imprimir a mensagem de processamento
        echo "Processing sample $samp"

        # Descomprimir o arquivo _R1.fastq.gz
        gunzip -c "$arquivo" > "$pasta_fastq/${samp}_R1.fastq"

        # Descomprimir o arquivo _R2.fastq.gz
        gunzip -c "$pasta_fastq/${samp}_R2.fastq.gz" > "$pasta_fastq/${samp}_R2.fastq"

        # Comando STAR
        STAR --runThreadN 12 --genomeDir "/home/ericgdp/lucas/mimivirus/Raw_data_RNAseq_Argentum/STAR/allgenomes" --readFilesIn "$pasta_fastq/${samp}_R1.fastq" "$pasta_fastq/${samp}_R2.fastq" --outFileNamePrefix "$dir_name/${samp}_"  --outReadsUnmapped Fastx

        # Comprimir novamente os arquivos _R1.fastq e _R2.fastq
        rm "$pasta_fastq/${samp}_R1.fastq"
        rm "$pasta_fastq/${samp}_R2.fastq"
    fi
done
