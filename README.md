[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
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

- __Edit__ *nextflow.config* :  
  ```
  gtdbtkDB = '/path/to/extracted/gtdbtk/database'    
  krakenDB = '/path/to/extracted/kraken2/database'
  ```
## How to run the pipeline
__This command will test the setup and download the containers for off-line use__:  
```
nextflow run mag-ont.nf -profile {docker,singularity},test
```
__Run on your data__:  
```
nextflow run mag-ont.nf -profile {docker,singularity},{local,hpc} --reads sample.fastq.gz --outdir results/
```

## Acknowledgement
This pipeline is inspired by [__nf-core/mag__](https://github.com/nf-core/mag) :  
> nf-core/mag: a best-practice pipeline for metagenome hybrid assembly and binning  
>Sabrina Krakau, Daniel Straub, Hadrien Gourlé, Gisela Gabernet, Sven Nahnsen.  
>NAR Genom Bioinform. 2022 Feb 2;4(1)  
>. doi: [10.1093/nargab/lqac007](https://academic.oup.com/nargab/article/4/1/lqac007/6520104)
