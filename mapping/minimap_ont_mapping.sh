#!/bin/bash

# Verifica se os parâmetros foram fornecidos
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <genoma_de_referencia.fasta> <diretorio_com_fastq_gz>"
    exit 1
fi

# Entrada do usuário
GENOMA_REF="$1"
FASTQ_DIR="$2"

# Nome do índice
INDEX="${GENOMA_REF}.mmi"

# Arquivo Excel de saída
OUTPUT_EXCEL="alignment_summary.xlsx"

# Cria o índice do genoma de referência, se necessário
if [ ! -f "$INDEX" ]; then
    echo "Criando índice do genoma de referência com minimap2..."
    minimap2 -d "$INDEX" "$GENOMA_REF"
    if [ $? -ne 0 ]; then
        echo "Erro ao criar o índice do genoma de referência."
        exit 1
    fi
    echo "Índice criado com sucesso: $INDEX"
else
    echo "Índice já existe: $INDEX"
fi

# Inicializa o arquivo de saída
echo -e "Sample\tAligned reads\tTotal reads" > "$OUTPUT_EXCEL"

# Processa todos os arquivos .fastq.gz no diretório
echo "Iniciando o mapeamento dos arquivos .fastq.gz..."
for FASTQ in "$FASTQ_DIR"/*.fastq.gz; do
    # Verifica se o arquivo existe
    if [ ! -f "$FASTQ" ]; then
        echo "Nenhum arquivo .fastq.gz encontrado no diretório $FASTQ_DIR."
        exit 1
    fi

    # Nome do arquivo de saída
    SAMPLE_NAME=$(basename "$FASTQ" .fastq.gz)
    OUTPUT_PAF="${SAMPLE_NAME}.paf"

    echo "Mapeando $FASTQ contra o genoma de referência..."
    minimap2 -x map-ont "$INDEX" "$FASTQ" > "$OUTPUT_PAF"

    if [ $? -eq 0 ]; then
        echo "Mapeamento concluído: $OUTPUT_PAF"

        # Calcula o total de reads na biblioteca (FASTQ)
        TOTAL_READS=$(zcat "$FASTQ" | awk 'NR % 4 == 1' | wc -l)

        # Calcula o total de reads alinhadas (PAF)
        ALIGNED_READS=$(wc -l < "$OUTPUT_PAF")

        echo "Sample: $SAMPLE_NAME | Aligned reads: $ALIGNED_READS | Total reads: $TOTAL_READS"

        # Adiciona ao arquivo Excel
        echo -e "$SAMPLE_NAME\t$ALIGNED_READS\t$TOTAL_READS" >> "$OUTPUT_EXCEL"
    else
        echo "Erro ao mapear $FASTQ. Pulando para o próximo arquivo."
    fi
done

echo "Resumo salvo em: $OUTPUT_EXCEL"
