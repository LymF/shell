#!/bin/bash

# Criar um novo diretório
dir_name="allgenomesunmapped"
mkdir -p "$dir_name"

# Obter o caminho completo para a pasta fastq/
pasta_fastq="/home/lucasyago/mimivirus/fastqs"

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

        # Comando Bowtie2
        bowtie2_index="/home/lucasyago/mimivirus/fastqs/allgenome_mapped/genome_index"
        genome_dirname=$(basename "$bowtie2_index")

        bowtie2 -x "$bowtie2_index" -1 "$pasta_fastq/${samp}_R1.fastq" -2 "$pasta_fastq/${samp}_R2.fastq" -S "$dir_name/${genome_dirname}_${samp}.sam" 2>&1 | tee "$dir_name/${samp}_mapping_summary.txt" 

        # Comprimir novamente os arquivos _R1.fastq e _R2.fastq
        rm "$pasta_fastq/${samp}_R1.fastq"
        rm "$pasta_fastq/${samp}_R2.fastq"

        # Converter SAM para BAM
        samtools view -bS "$dir_name/${genome_dirname}_${samp}.sam" > "$dir_name/${genome_dirname}_${samp}.bam"

        # Selecionar reads não alinhadas
        samtools view -b -f 12 -F 256 "$dir_name/${genome_dirname}_${samp}.bam" > "$dir_name/${genome_dirname}_${samp}_bothReadsUnmapped.bam"

        # Ordenar BAM pelo nome
        samtools sort -n -m 5G -@ 2 "$dir_name/${genome_dirname}_${samp}_bothReadsUnmapped.bam" -o "$dir_name/${genome_dirname}_${samp}_bothReadsUnmapped_sorted.bam"

        # Converter BAM para FastQ
        samtools fastq -@ 8 "$dir_name/${genome_dirname}_${samp}_bothReadsUnmapped_sorted.bam" -1 "$dir_name/${genome_dirname}_${samp}_host_removed_R1.fastq.gz" -2 "$dir_name/${genome_dirname}_${samp}_host_removed_R2.fastq.gz" -0 /dev/null -s /dev/null -n

        # Remover arquivos temporários
        rm "$dir_name/${genome_dirname}_${samp}.sam" "$dir_name/${genome_dirname}_${samp}.bam" "$dir_name/${genome_dirname}_${samp}_bothReadsUnmapped.bam" "$dir_name/${genome_dirname}_${samp}_bothReadsUnmapped_sorted.bam"
    fi
done

