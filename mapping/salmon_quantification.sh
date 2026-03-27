#!/bin/bash

# Diretório de trabalho
workdir="/home/lucasyago/urticae"

# ÍNDICE Salmon
salmon_index="$workdir/indexurticae"

# Número máximo de threads
threads=15

#Biblioteca
library="A"

# Lista de SRAs (separadas por espaços)
sra_list="SRR16642611 SRR16643413 SRR8844439 SRR28000928 SRR13675288 DRR196680 
SRR22425482 SRR22425481 SRR22425483 SRR22425484 SRR122425487 
SRR12329844 SRR12329855 SRR12329854 SRR12329853 SRR12329852 
SRR12329851 SRR12329850 SRR4043738 SRR10741871 SRR11260806 
SRR26166044 SRR25660809 SRR23919708 SRR22881259 SRR22129943 
SRR17777943 DRR196683 SRR27896439"

#sra_list= "/home/lucasyago/urticae/accessionlisturticaepaired.txt"

# Processa cada SRA na lista
for sra_number in $sra_list; do
 # Baixa a SRA com iseq
    iseq -i "$sra_number" -g  
 # Baixa a SRA com fasterqdump
    #fasterq-dump -v "$sra_number" --split-files -t "$threads" -o "$sra_number"

    # Quantificação com Salmon
    salmon quant -i "$salmon_index" -p "$threads" -l "$library" -1 "$workdir/$sra_number_1.fastq.gz" -2 "$workdir/$sra_number_2.fastq.gz" -o "$workdir/$sra_number"

    # Remove arquivos FASTQ (opcional)
    rm "$workdir/$sra_number_1.fastq.gz" "$workdir/$sra_number_2.fastq.gz" "$workdir/$sra_number.metadata.tsv"

done

