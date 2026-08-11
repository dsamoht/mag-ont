[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.4-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-4.1.0-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/4.1.0)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

```
                                         _
 _ __ ___   __ _  __ _        ___  _ __ | |_
| '_ ` _ \ / _` |/ _` |_____ / _ \| '_ \| __|
| | | | | | (_| | (_| |_____| (_) | | | | |_
|_| |_| |_|\__,_|\__, |      \___/|_| |_|\__|
                 |___/

Long reads-first metagenome assembly and binning
with support for short reads

     Github: https://github.com/dsamoht/mag-ont
     Version: v1.4.0
```

## pipeline overview

```mermaid
flowchart TD
    IN[/"samplesheet<br/>long reads · short reads · assembly"/]

    subgraph QC ["long-read QC — per sample"]
        NPRAW["NanoPlot<br/><i>raw reads</i>"]:::opt
        PORE["Porechop_ABI<br/><i>adapter removal</i>"]:::opt
        CHOP["Chopper<br/><i>length / quality filter</i>"]
        NPQC["NanoPlot<br/><i>filtered reads</i>"]:::opt
        PORE --> CHOP --> NPQC
    end

    CAT["cat<br/><i>pool reads per group</i>"]

    subgraph ASM ["assembly — per group"]
        FLYE["Flye"]
        MEDAKA["Medaka<br/><i>consensus polishing</i>"]:::opt
        MDBG["metaMDBG"]
        FLYE --> MEDAKA
    end

    CONTIGS[["contigs<br/><i>assembled or user-provided</i>"]]

    subgraph GENES ["gene prediction"]
        PYRO["Pyrodigal<br/><i>100 MB chunks</i>"] --> MERGE["merge<br/><i>gff · fna · faa</i>"]
    end

    subgraph SC ["single-contig MAGs"]
        SEQKIT["SeqKit<br/><i>contigs ≥ --sc_mag_minimum,<br/>one file each</i>"]
        CKM1["CheckM<br/><i>all candidates of a group in one run</i>"]:::opt
        GATE{"completeness ≥<br/>--sc_mag_min_completeness"}
        SCMAG[["single-contig MAGs"]]
        SEQKIT --> CKM1 --> GATE
        GATE -->|yes| SCMAG
    end

    CATC["cat contigs<br/><i>short contigs + rejected candidates,<br/>original headers restored</i>"]
    TOBIN[["contigs to bin"]]

    subgraph MAP ["read mapping — per sample"]
        MM2["minimap2<br/><i>long reads</i>"]
        BWA["bwa-mem<br/><i>short reads</i>"]
        ST["samtools<br/><i>sort · index</i>"]
        MM2 --> ST
        BWA --> ST
    end

    CVC["CoverM contig<br/>+ gene-length normalization"]

    subgraph BIN ["binning — per group"]
        MB["MetaBAT2"]
        MX["MaxBin2"]:::opt
        CC["CONCOCT"]:::opt
        SB["SemiBin2"]:::opt
    end

    DAS["DAS_Tool<br/><i>bin refinement</i>"]
    FINAL[["final bin set<br/><i>DAS_Tool bins + single-contig MAGs</i>"]]

    subgraph QA ["MAG quality & taxonomy"]
        CKM2["CheckM<br/><i>completeness · contamination</i>"]:::opt
        GTDB["GTDB-Tk<br/><i>taxonomy</i>"]:::opt
        CVG["CoverM genome<br/>+ normalization"]
    end

    SUM[["MAG summary<br/><i>contig2bin · per-MAG table</i>"]]
    MQC["MultiQC"]:::opt

    IN -->|long reads| NPRAW
    IN -->|long reads| PORE
    IN -->|"assembly (skips QC & assembly)"| CONTIGS
    IN -.->|short reads| BWA
    CHOP --> CAT
    CAT --> FLYE
    CAT --> MDBG
    MEDAKA --> CONTIGS
    FLYE --> CONTIGS
    MDBG --> CONTIGS

    CONTIGS --> PYRO
    CONTIGS --> SEQKIT
    CONTIGS --> MM2
    CONTIGS --> BWA
    CHOP --> MM2

    SEQKIT -->|"short contigs"| CATC
    GATE -.->|"no"| CATC
    CATC --> TOBIN

    TOBIN --> MB
    TOBIN --> MX
    TOBIN --> CC
    TOBIN --> SB
    TOBIN --> DAS

    ST --> CVC
    MERGE --> CVC
    ST --> MB
    MB -->|depth| MX
    ST --> CC
    ST --> SB

    MB --> DAS
    MX --> DAS
    CC --> DAS
    SB --> DAS

    DAS --> FINAL
    SCMAG --> FINAL

    FINAL --> CKM2
    FINAL --> GTDB
    FINAL --> CVG
    ST --> CVG

    CKM2 --> SUM
    GTDB --> SUM
    CVG --> SUM

    NPRAW --> MQC
    NPQC --> MQC
    PORE --> MQC
    CVC --> MQC
    CKM2 --> MQC

    classDef opt stroke-dasharray: 5 3;
```

*Dashed boxes are optional steps that can be turned off with the matching `--skip_*` parameter.*

## TL;DR

```bash
nextflow run main.nf \
  -profile singularity,drac \
  --gtdbtk_db /path/to/uncompressed/db \
  --input ./tests/data/samplesheet_test.csv \
  --outdir ./tests/outdir
```

## software dependencies

- [Nextflow](https://www.nextflow.io/)
- [Docker](https://www.docker.com/) or [Apptainer (Singularity)](https://apptainer.org/)

## database

- [GTDB-Tk database - release 226](https://ecogenomics.github.io/GTDBTk/installing/index.html#gtdb-tk-reference-data) (uncompressed)

## usage

select :

1. a container engine : `docker`, `singularity`, `apptainer`, `podman`, `shifter`, `charliecloud` or `wave` (`conda`/`mamba` are also available). Most HPC environments have apptainer already installed. Docker is mostly used on local workstations.
2. optionally, an execution profile : `test` runs a minimal dataset to check your installation, `drac` runs with the slurm executor on the Digital Research Alliance of Canada clusters or similar slurm-based HPC, and `gpu` passes a GPU through to Medaka and SemiBin2. With no execution profile the pipeline runs locally with the default resources from [conf/base.config](./conf/base.config).

Resource requests and tool arguments can be overridden with your own config, see [docs/usage.md](./docs/usage.md).

```bash
nextflow run main.nf \
  -profile {docker/singularity/apptainer}[,test][,drac] \
  --gtdbtk_db /path/to/uncompressed/db \
  --input ./tests/data/samplesheet_test.csv \
  --outdir ./tests/outdir
```

Full documentation: [usage](./docs/usage.md) and [output](./docs/output.md).

## sample sheet specification

The pipeline uses a CSV sample sheet to manage input data and define how samples are grouped for co-assembly and binning.

The CSV must contain exactly **6 columns** with the following headers:

| column         | description                                                                                                      |
| -------------- | ---------------------------------------------------------------------------------------------------------------- |
| sample_id      | unique name for the sample.                                                                                      |
| group          | identifier to group samples together for co-processing. All samples that share this identifier are co-assembled. |
| assembly_fasta | path to a pre-existing assembly. If provided, assembly is skipped and the pipeline starts at the binning step.   |
| long_reads     | path to long-read FASTQ file.                                                                                    |
| short_reads_1  | path to post-qc forward R1 FASTQ file.                                                                           |
| short_reads_2  | path to post-qc reverse R2 FASTQ file.                                                                           |

> [!NOTE]
> When both types of reads are provided and no pre-existing assembly is provided, assembly is made with the long reads and binning is made with the short reads.
> Short reads are only used for binning and they are chosen over long reads.

- **Read consistency:** Short reads must be paired. If short_reads_1 is provided, short_reads_2 must also be provided.
- **Minimum requirements:** Each group must contain at least an assembly_fasta OR long_reads.
- **Group integrity:** All samples within the same group must point to the **exact same** assembly_fasta if a pre-existing assembly is provided.
- **Read type matching:** Within a group, you cannot mix "long-read only" samples with "short-read only" samples. This ensures compatibility during binning and coverage calculation.

### input example

```csv
sample_id,group,assembly_fasta,long_reads,short_reads_1,short_reads_2
test4,ont_test4,,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/TEST4_ONT.fastq.gz,,
test3,ont_test3,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/ont_test3.assembly.fasta,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/TEST3_ONT.fastq.gz,,
test1,coassembly,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/coassembly.assembly.fasta,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/TEST3_ONT.fastq.gz,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/TEST1_R1.fastq.gz,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/TEST1_R2.fastq.gz
test2,coassembly,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/coassembly.assembly.fasta,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/TEST4_ONT.fastq.gz,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/TEST2_R1.fastq.gz,https://github.com/dsamoht/mag-ont/raw/refs/heads/main/tests/data/TEST2_R2.fastq.gz
```

## acknowledgement

This pipeline is inspired by [**nf-core/mag**](https://github.com/nf-core/mag) :

> nf-core/mag: a best-practice pipeline for metagenome hybrid assembly and binning  
> Sabrina Krakau, Daniel Straub, Hadrien Gourlé, Gisela Gabernet, Sven Nahnsen.  
> NAR Genom Bioinform. 2022 Feb 2;4(1)
> doi: [10.1093/nargab/lqac007](https://academic.oup.com/nargab/article/4/1/lqac007/6520104)
