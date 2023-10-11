[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

# Metagenome-assembled genomes from long reads
## Introduction
![alt text](/img/mag-ont_schema.png)

> *__Note__* : this is a *long-reads-first* pipeline. If you give both long reads and paired-end short reads, the draft assembly will first be done with long reads, then "polished" with short reads.
## Dependencies
- __Software :__  
  [Nextflow](https://www.nextflow.io/)  
  [Docker](https://www.docker.com/) and/or [Apptainer/Singularity](https://apptainer.org/)  

- __Data :__  
  [GTDB-Tk database](https://ecogenomics.github.io/GTDBTk/installing/index.html#gtdb-tk-reference-data)  
  A pre-built [Kraken2 database](https://benlangmead.github.io/aws-indexes/k2)

- __Edit__ *nextflow.config* at lines 15-16 :  
  gtdbtk_db = '/path/to/extracted/gtdbtk/database'    
  kraken_db = '/path/to/extracted/kraken2/database'

## How to run the pipeline
__This command will test the setup and download the containers for off-line use__:  
```
nextflow run mag-ont.nf -profile {docker,singularity},test
```
__Run on your data__:  
```
nextflow run mag-ont.nf -profile {docker,singularity},{local,hpc} --reads sample.fastq.gz --outdir results/
```
