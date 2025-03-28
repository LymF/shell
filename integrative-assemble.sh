#!/bin/bash

# Parâmetros do usuário
NUM_THREADS=24  # Número de threads para as ferramentas
RAM_SPADES=24000  # Memória para SPAdes em MB
RAM_OTHER=24  # Memória para as outras ferramentas em GB
GENOME_REF="/home/lucasyago/remontagem_libs/cocoa-index/cocoa-index"  # Caminho para o genoma de referência
INPUT_DIR="/home/lucasyago/remontagem_libs/rem-libs"  # Diretório dos arquivos FASTA
OUTPUT_DIR="/home/lucasyago/remontagem_libs/rem-output"  # Diretório de saída

mkdir -p "$OUTPUT_DIR/non_mapped_reads"
mkdir -p "$OUTPUT_DIR/assemblies"

# Loop pelos arquivos FASTA
for FILE in "$INPUT_DIR"/*_01.fasta; do
    SAMPLE=$(basename "$FILE" _01.fasta)
    READ1="$INPUT_DIR/${SAMPLE}_01.fasta"
    READ2="$INPUT_DIR/${SAMPLE}_02.fasta"
    
    # 1. Mapeamento contra o genoma de referência (Bowtie2)
    bowtie2  -x "$GENOME_REF" -f -1 "$READ1" -2 "$READ2" \
            --threads "$NUM_THREADS" --un-conc "$OUTPUT_DIR/non_mapped_reads/${SAMPLE}_unmapped.fq"
    
    UNMAPPED_R1="$OUTPUT_DIR/non_mapped_reads/${SAMPLE}_unmapped.1.fq"
    UNMAPPED_R2="$OUTPUT_DIR/non_mapped_reads/${SAMPLE}_unmapped.2.fq"
    
    # 2. Montagem com SPAdes
    spades.py --rna -1 "$UNMAPPED_R1" -2 "$UNMAPPED_R2" \
              -o "$OUTPUT_DIR/assemblies/${SAMPLE}_spades" \
              --threads "$NUM_THREADS" --memory "$RAM_SPADES"
    
    # 3. Montagem com MEGAHIT
    megahit -1 "$UNMAPPED_R1" -2 "$UNMAPPED_R2" \
            -o "$OUTPUT_DIR/assemblies/${SAMPLE}_megahit" \
            --num-threads "$NUM_THREADS" --memory "$RAM_OTHER"g
    
    # 4. Montagem com Trinity
    Trinity --seqType fq --left "$UNMAPPED_R1" --right "$UNMAPPED_R2" \
            --CPU "$NUM_THREADS" --max_memory "$RAM_OTHER"G \
            --output "$OUTPUT_DIR/assemblies/${SAMPLE}_trinity"
    
    # 5. Unindo montagens
    cat "$OUTPUT_DIR/assemblies/${SAMPLE}_spades/contigs.fasta" \
        "$OUTPUT_DIR/assemblies/${SAMPLE}_megahit/final.contigs.fa" \
        "$OUTPUT_DIR/assemblies/${SAMPLE}_trinity/Trinity.fasta" > "$OUTPUT_DIR/assemblies/${SAMPLE}_merged.fasta"
    
    # 6. Redução de redundância com CD-HIT e CAP3
    cd-hit-est -i "$OUTPUT_DIR/assemblies/${SAMPLE}_merged.fasta" -o "$OUTPUT_DIR/assemblies/${SAMPLE}_cdhit.fasta" -c 0.90 -n 5 -T "$NUM_THREADS"
    cap3 "$OUTPUT_DIR/assemblies/${SAMPLE}_cdhit.fasta" > "$OUTPUT_DIR/assemblies/${SAMPLE}_final_assembly.fasta"

done

echo "Pipeline concluída!"
