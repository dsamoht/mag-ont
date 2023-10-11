# Metagenome-assembled genomes from long reads
## Introduction
![alt text](/img/mag-ont_schema.png)

> *__Note__* : this is a *long-reads-first* pipeline. If you give both long reads and paired-end short reads, the draft assembly will first be done with long reads, then "polished" with short reads.
## Dependencies
#### Software :
- [Nextflow](https://www.nextflow.io/)
- [Docker](https://www.docker.com/) and/or [Apptainer/Singularity](https://apptainer.org/)
#### Data :
- [GTDB-Tk database](https://ecogenomics.github.io/GTDBTk/installing/index.html#gtdb-tk-reference-data)
- A pre-built [Kraken2 database](https://benlangmead.github.io/aws-indexes/k2)

#### Edit nextflow.config at lines 15-16:

gtdbtk_db = '/path/to/extracted/database'  
kraken_db = '/path/to/extracted/database'

## How to run the pipeline
### This command will test the setup and download the containers for off-line use:
```
nextflow run mag-ont.nf -profile {docker,singularity},test
```
### Run on your data:
```
nextflow run mag-ont.nf -profile {docker,singularity},{local,hpc} --reads sample.fastq.gz --outdir results/
```
