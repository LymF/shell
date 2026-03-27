# shell — Bioinformatics Shell Pipeline Scripts

A collection of Bash scripts for common bioinformatics pipeline steps, organized by functional category. Scripts cover de novo assembly, read mapping, sequence homology searches, virus identification workflows, and utility operations — primarily designed for RNA-seq, small RNA, and viral metagenomics analyses.

## Repository structure

```
shell/
├── assembly/   # De novo assembly and contig post-processing
├── mapping/    # Read alignment and quantification
├── blast/      # Local BLAST searches
├── virus/      # Virus identification pipelines
└── utils/      # Utility and post-processing scripts
```

---

## assembly/

Scripts for de novo assembly of sequencing reads and contig post-processing.

| Script | Tool | Description |
|---|---|---|
| `ont_assembly_pipeline.sh` | Flye / Minimap2 / Medaka | End-to-end Oxford Nanopore Technology (ONT) assembly pipeline — basecalled reads → polished assembly |
| `integrative_assembly.sh` | SPAdes + MEGAHIT + CAP3 | Integrative assembly combining SPAdes and MEGAHIT outputs, followed by CAP3 contig merging |
| `cap3_assembly.sh` | CAP3 | Runs CAP3 on a FASTA file for contig assembly from overlapping sequences |
| `cap3_to_fasta.sh` | CAP3 | Merges CAP3 `.cap.contigs` and `.cap.singlets` outputs into a single FASTA file |
| `cdhit_clustering.sh` | CD-HIT-EST | Clusters nucleotide sequences at a defined identity threshold (default 95%) to remove redundancy |
| `cdhit_cap3_to_fasta.sh` | CAP3 + CD-HIT-EST | Sequential CAP3 assembly followed by CD-HIT-EST clustering and FASTA merging |
| `cdhit_no_conversion.sh` | CD-HIT-EST | CD-HIT-EST clustering without downstream format conversion |
| `reassembly_trimgalore.sh` | Trim Galore + assembler | Quality-trims reads with Trim Galore and re-assembles from a FASTA input |

**Dependencies:** CAP3, CD-HIT, SPAdes, MEGAHIT, Trim Galore, Flye, Minimap2

---

## mapping/

Scripts for read alignment to reference genomes and transcript quantification.

| Script | Tool | Description |
|---|---|---|
| `bowtie2_mapping.sh` | Bowtie2 + SAMtools | Maps paired-end reads to a reference genome; outputs sorted BAM and mapping statistics |
| `minimap_ont_mapping.sh` | Minimap2 + SAMtools | Maps ONT long reads to a reference assembly using `minimap2 -ax map-ont`; outputs sorted BAM |
| `star_alignment.sh` | STAR | Two-pass STAR alignment for RNA-seq reads with splice-aware mapping; generates BAM and splice junction files |
| `salmon_quantification.sh` | Salmon | Quasi-mapping-based transcript quantification with Salmon `quant`; outputs `quant.sf` per sample |
| `salmon_quantification_v2.sh` | Salmon | Updated Salmon quantification with additional parameters for bias correction and validation mode |

**Dependencies:** Bowtie2, Minimap2, STAR, Salmon, SAMtools

---

## blast/

Scripts for running local BLAST searches.

| Script | Tool | Description |
|---|---|---|
| `blastn.sh` | BLASTn | Nucleotide vs. nucleotide search; configurable e-value, threads, and output format (default: tabular -outfmt 6) |
| `blastx.sh` | BLASTx | Translated nucleotide vs. protein search; suitable for open reading frame identification against protein databases |

**Dependencies:** BLAST+ suite

---

## virus/

Shell-based virus identification pipelines for small RNA and RNA-seq datasets.

| Script | Description |
|---|---|
| `virus_identification.sh` | Core virus identification pipeline — quality filtering, host subtraction, de novo assembly, and BLASTx/DIAMOND annotation |
| `virus_identification_apis.sh` | Virus identification pipeline configured for the Apis HPC cluster (cluster-specific paths and resource settings) |
| `virus_identification_dicer.sh` | Virus identification pipeline configured for the Dicer HPC cluster (cluster-specific paths and resource settings) |
| `virus_identification_no_mapping.sh` | Streamlined virus identification that skips host mapping; intended for libraries without a reference genome |

These scripts are modular and can be adapted by modifying the tool paths and database references at the top of each file.

**Dependencies:** FastQC, Trim Galore / cutadapt, Bowtie2, SAMtools, SPAdes, MEGAHIT, DIAMOND, BLAST+

---

## utils/

Utility scripts for post-processing and file manipulation.

| Script | Description |
|---|---|
| `pattern_search.sh` | Wrapper around `grep` for searching patterns across multiple FASTA or tabular files with formatted output |
| `rename_scaffolds.sh` | Renames scaffold/contig headers in a FASTA file to a sequential, standardized format (e.g., `scaffold_001`, `scaffold_002`) |

---

## Usage

All scripts are self-contained Bash scripts. Input paths, thread counts, and tool parameters are defined as variables at the top of each file — edit before running.

### Running a script

```bash
# Make executable (first time)
chmod +x mapping/bowtie2_mapping.sh

# Run
bash mapping/bowtie2_mapping.sh
```

### Example — Bowtie2 mapping

Edit `mapping/bowtie2_mapping.sh` and set:

```bash
INDEX="/path/to/bowtie2_index/genome"
READS_1="/path/to/sample_R1.fastq.gz"
READS_2="/path/to/sample_R2.fastq.gz"
OUTPUT_DIR="/path/to/output/"
THREADS=16
```

Then run:

```bash
bash mapping/bowtie2_mapping.sh
```

### Example — ONT assembly

Edit `assembly/ont_assembly_pipeline.sh` and set:

```bash
READS="/path/to/reads.fastq.gz"
GENOME_SIZE="500m"
OUTPUT_DIR="/path/to/assembly_output/"
THREADS=32
```

Then run:

```bash
bash assembly/ont_assembly_pipeline.sh
```

---

## Notes

- Scripts assume tools are installed and available in `$PATH`. Use conda environments or module systems to manage dependencies.
- Most scripts include basic checkpoints — re-running will overwrite existing outputs unless modified to check for existing files.
- Thread and memory parameters should be adjusted to match your HPC or local machine specifications.
