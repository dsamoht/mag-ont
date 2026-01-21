[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A525.10.2-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

![alt text](/assets/img/mag-ont_v1.2.0.png)

```
                                         _   
 _ __ ___   __ _  __ _        ___  _ __ | |_ 
| '_ ` _ \ / _` |/ _` |_____ / _ \| '_ \| __|
| | | | | | (_| | (_| |_____| (_) | | | | |_ 
|_| |_| |_|\__,_|\__, |      \___/|_| |_|\__|
                 |___/                       

Automation of metagenome assembly and binning
with support for Oxford Nanopore reads
     
     Github: https://github.com/dsamoht/mag-ont
     Version: v1.2.0

```

## Software dependencies

* [Nextflow](https://www.nextflow.io/)
* [Docker](https://www.docker.com/) or [Apptainer (Singularity)](https://apptainer.org/)

## Database

* [GTDB-Tk database - release 226](https://ecogenomics.github.io/GTDBTk/installing/index.html#gtdb-tk-reference-data) (uncompressed)

## Usage

Once the dependencies are installed, you can directly use the pipeline. You just have to choose a container engine and a workload capacity (`test`: 1 cpu, `local` : 8 cpus, `hpc` : 20 cpus). These profiles can be edited in [nextflow.config](https://www.google.com/search?q=./nextflow.config).

```bash
nextflow run main.nf \
  -profile {docker/singularity/apptainer},{test/local/hpc} \
  --gtdbtk_db /path/to/uncompressed/db \
  --input ./test_data/samplesheet.csv \
  --outdir ./test_data/test_out

```

You can also download the container images for further use (in a scenario where compute nodes are not connected to internet) by using the `install` profile. Images are pulled according to the chosen container engine (`docker` (default), `singularity` or `apptainer`).

```bash
nextflow run main.nf \
  -profile {docker/singularity/apptainer},install
```


## Sample sheet specification

The pipeline uses a CSV sample sheet to manage input data and define how samples are grouped for co-assembly and binning.

### Column Structure

The CSV must contain exactly **6 columns** with the following headers:

| Column | Description |
| --- | --- |
| `sample_id` | Unique name for the sample. |
| `group` | Identifier to group samples together for co-processing. |
| `assembly_fasta` | (Optional) Path to a pre-existing assembly. |
| `long_reads` | (Optional) Path to ONT/Long-read FASTQ file. |
| `short_reads_1` | (Optional) Path to Forward R1 FASTQ. |
| `short_reads_2` | (Optional) Path to Reverse R2 FASTQ. |


### Validation Logic

The pipeline performs several automated checks:

* **Read consistency:** Short reads must be paired. If `short_reads_1` is provided, `short_reads_2` must also be present.
* **Minimum requirements:** Each group must contain at least an `assembly_fasta` OR `long_reads` to be valid.
* **Group integrity:** All samples within the same `group` must point to the **exact same** `assembly_fasta` if one is provided.
* **Read type matching:** Within a group, you cannot mix "long-read only" samples with "short-read only" samples. This ensures compatibility during binning and coverage calculation.

### Examples

**Standard long-lead assembly:**

```csv
sample_id,group,assembly_fasta,long_reads,short_reads_1,short_reads_2
sample_1_ont,1,,./test_data/s1_ont.fastq.gz,,
```

**Co-assembly:**
> [!NOTE]
> When both reads types are provided and no pre-existing assembly is given, assembly is made with the long reads and binning is made with short reads.
> If this strategy is not optimal for your experimental design, I strongly suggest to assemble before running `mag-ont`.
> Then use the `mag-ont` with your pre-existing assemblies (see "Using pre-existing assembly")  

```csv
sample_id,group,assembly_fasta,long_reads,short_reads_1,short_reads_2
sample_1_co,3,,./data/s1_ont.fq.gz,./data/s1_R1.fq.gz,./data/s1_R2.fq.gz
sample_2_co,3,,./data/s2_ont.fq.gz,./data/s2_R1.fq.gz,./data/s2_R2.fq.gz
```

**Using pre-existing assembly:**
```csv
sample_id,group,assembly_fasta,long_reads,short_reads_1,short_reads_2
sample_1,group_A,./ref/asm.fa,./data/s1_ont.fq.gz,./data/s1_R1.fq.gz,./data/s1_R2.fq.gz
```

## Acknowledgement
This pipeline is inspired by [__nf-core/mag__](https://github.com/nf-core/mag) :  
> nf-core/mag: a best-practice pipeline for metagenome hybrid assembly and binning  
>Sabrina Krakau, Daniel Straub, Hadrien Gourlé, Gisela Gabernet, Sven Nahnsen.  
>NAR Genom Bioinform. 2022 Feb 2;4(1)  
>doi: [10.1093/nargab/lqac007](https://academic.oup.com/nargab/article/4/1/lqac007/6520104)