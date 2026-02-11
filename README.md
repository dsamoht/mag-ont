[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A525.10.2-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

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

![alt text](/assets/img/mag-ont_v1.2.0.png)

## Software dependencies

* [Nextflow](https://www.nextflow.io/)
* [Docker](https://www.docker.com/) or [Apptainer (Singularity)](https://apptainer.org/)

## Database

* [GTDB-Tk database - release 226](https://ecogenomics.github.io/GTDBTk/installing/index.html#gtdb-tk-reference-data) (uncompressed)

## Usage
Select :
  1) a container engine : docker or apptainer/singularity. Most HPC environment have apptainer already installed. Docker is mostly used for local computer.
  2) a workload capacity : test, base or drac. test is for testing your installation. base if for running the pipeline as a single task, like on a local computer. drac is for running with the slurm executor on the Digital Research Alliance of Canada clusters.

These profiles can be edited in [nextflow.config](./nextflow.config).

```bash
nextflow run main.nf \
  -profile {docker/singularity/apptainer},{test,base,drac} \
  --gtdbtk_db /path/to/uncompressed/db \
  --input ./test/samplesheet_test.csv \
  --outdir ./test/mag-ont_outdir
```

You can also download the container images for further use by using the install profile. Images are pulled according to the chosen container engine.

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
| `group` | Identifier to group samples together for co-processing. All samples that share this identifier are co-assembled.|
| `assembly_fasta` | Path to a pre-existing assembly. If provided, assembly is skipped and the pipeline starts at the binning step. |
| `long_reads` | Path to long-read FASTQ file. |
| `short_reads_1` | Path to post-qc forward R1 FASTQ file. |
| `short_reads_2` | Path to post-qc reverse R2 FASTQ file. |

> [!NOTE]
> When both types of reads are provided and no pre-existing assembly is provided, assembly is made with the long reads and binning is made with the short reads.
> Short reads are only used for binning and they are chosen over long reads.

* **Read consistency:** Short reads must be paired. If `short_reads_1` is provided, `short_reads_2` must also be provided.
* **Minimum requirements:** Each group must contain at least an `assembly_fasta` OR `long_reads`.
* **Group integrity:** All samples within the same `group` must point to the **exact same** `assembly_fasta` if a pre-existing assembly is provided.
* **Read type matching:** Within a group, you cannot mix "long-read only" samples with "short-read only" samples. This ensures compatibility during binning and coverage calculation.

## Acknowledgement
This pipeline is inspired by [__nf-core/mag__](https://github.com/nf-core/mag) :  
>nf-core/mag: a best-practice pipeline for metagenome hybrid assembly and binning  
>Sabrina Krakau, Daniel Straub, Hadrien Gourlé, Gisela Gabernet, Sven Nahnsen.  
>NAR Genom Bioinform. 2022 Feb 2;4(1)  
>doi: [10.1093/nargab/lqac007](https://academic.oup.com/nargab/article/4/1/lqac007/6520104)
