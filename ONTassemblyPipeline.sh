#!/bin/bash

# Caminhos e parâmetros
REF="reference_genome.fasta"
FASTQ_DIR="/home/lucasyago/chikv"  # Diretório contendo os FASTQ
OUT_DIR="/home/lucasyago/chikv/output"  # Diretório de saída
GENOME_SIZE="11.8k"  # Tamanho aproximado do genoma

# Criar pasta de saída
mkdir -p $OUT_DIR

# Loop para processar cada arquivo FASTQ
for FILE in ${FASTQ_DIR}/*merged.fastq.gz; do
    SAMPLE=$(basename $FILE .fastq.gz)
    SAMPLE_OUT="$OUT_DIR/$SAMPLE"
    mkdir -p $SAMPLE_OUT

    echo "Processando $SAMPLE..."

    # 1. Filtrar leituras de baixa qualidade com Filtlong
    filtlong --min_length 500 --min_mean_q 5 $FILE > $SAMPLE_OUT/${SAMPLE}_filtered.fastq

    # 2. Montar o genoma com Flye
    flye --nano-raw $SAMPLE_OUT/${SAMPLE}_filtered.fastq --genome-size $GENOME_SIZE --out-dir $SAMPLE_OUT/flye --threads 4 --min-overlap 500

    # 3. Montar o genoma com Canu
    canu -p $SAMPLE -d $SAMPLE_OUT/canu genomeSize=$GENOME_SIZE -nanopore $SAMPLE_OUT/${SAMPLE}_filtered.fastq useGrid=false corMinCoverage=2

    # 4. Montar o genoma com Unicycler
    unicycler -l $SAMPLE_OUT/${SAMPLE}_filtered.fastq -o $SAMPLE_OUT/unicycler --threads 4

    # 5. Avaliar cada montagem inicial com QUAST
    quast.py -r $REF -o $SAMPLE_OUT/quast_flye $SAMPLE_OUT/flye/assembly.fasta
    quast.py -r $REF -o $SAMPLE_OUT/quast_canu $SAMPLE_OUT/canu/$SAMPLE.contigs.fasta
    quast.py -r $REF -o $SAMPLE_OUT/quast_unicycler $SAMPLE_OUT/unicycler/assembly.fasta

    # 6. Polir as montagens individuais com Medaka
    medaka_consensus -i $SAMPLE_OUT/${SAMPLE}_filtered.fastq -d $SAMPLE_OUT/flye/assembly.fasta -o $SAMPLE_OUT/medaka_flye -t 4
    medaka_consensus -i $SAMPLE_OUT/${SAMPLE}_filtered.fastq -d $SAMPLE_OUT/canu/$SAMPLE.contigs.fasta -o $SAMPLE_OUT/medaka_canu -t 4
    medaka_consensus -i $SAMPLE_OUT/${SAMPLE}_filtered.fastq -d $SAMPLE_OUT/unicycler/assembly.fasta -o $SAMPLE_OUT/medaka_unicycler -t 4

    # 7. Mesclar as montagens polidas com seqtk
    cat $SAMPLE_OUT/medaka_flye/consensus.fasta \
        $SAMPLE_OUT/medaka_canu/consensus.fasta \
        $SAMPLE_OUT/medaka_unicycler/consensus.fasta > $SAMPLE_OUT/merged_consensus.fasta

    # 8. Polir a montagem combinada com Medaka
    medaka_consensus -i $SAMPLE_OUT/${SAMPLE}_filtered.fastq -d $SAMPLE_OUT/merged_consensus.fasta -o $SAMPLE_OUT/medaka_merged -t 4

    # 9. Avaliar montagem polida final com QUAST
    quast.py -r $REF -o $SAMPLE_OUT/quast_medaka_merged $SAMPLE_OUT/medaka_merged/consensus.fasta

    echo "Processamento de $SAMPLE concluído."
done

echo "Pipeline finalizada."
