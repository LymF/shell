#!/bin/bash

# Diretório de trabalho
workdir="/home/lucasyago/salmon/salmon"

# ÍNDICE Salmon
salmon_index="$workdir/salmon_index"

# Número máximo de threads
threads=15

# Biblioteca
library="A"

# Lista de SRAs (separadas por espaços)
sra_list="SRR23341994 SRR23341995 SRR23341996 SRR21659836 SRR21659835 SRR21659839 SRR21659840 SRR21659845 SRR21659846 SRR21659849 SRR21659850 SRR14087800 SRR14087805
SRR14087857 SRR14087850 SRR14087848 SRR14087851 SRR14087841 SRR14087803 SRR14087814 SRR14087821 SRR14087827 SRR14087832 SRR14087836 SRR14087801 SRR14087806 SRR14087802 SRR12151823
SRR12151822 SRR12151820 SRR12151821 SRR12151824 SRR12151825 SRR7276078 SRR7276075 SRR7276076 SRR7276077 SRR7276079 SRR7276080
"
# Processa cada SRA na lista
for sra_number in $sra_list; do
    # Baixa a SRA com iseq
    iseq -i "$sra_number" -a -g

    # Define os nomes dos arquivos FASTQ (assumindo que iseq gera arquivos .fastq.gz)
    fastq1="$workdir/${sra_number}_1.fastq.gz"
    fastq2="$workdir/${sra_number}_2.fastq.gz"

    # Quantificação com Salmon
    salmon quant -i "$salmon_index" -p "$threads" -l "$library" -1 "$fastq1" -2 "$fastq2" -o "$workdir/$sra_number" --validateMappings

    # Remove arquivos FASTQ (opcional)
    rm "$fastq1" "$fastq2"
    rm "$workdir/$sra_number.metadata.tsv"

done
