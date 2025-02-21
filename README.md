[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

# Installation
## Dependencies
- __Software :__  
  - [Nextflow](https://www.nextflow.io/)  
  - [Docker](https://www.docker.com/) and/or [Apptainer/Singularity](https://apptainer.org/)  

- __Database :__
  - [GTDB-Tk database](https://ecogenomics.github.io/GTDBTk/installing/index.html#gtdb-tk-reference-data)

- __Edit__ this line in *nextflow.config* file:  
  ```
  gtdbtk_db = '/absolute/path/to/extracted/gtdbtk/release'
  ```
## Installation
__1) Test your setup and download the containers for future use (to run once):__
```
nextflow run main.nf \
  -profile {docker,singularity},local,test
```
__2) Run on your data__:
```
nextflow run main.nf \
  -profile {docker,singularity},{hpc,local} \
  --reads lr_sample.fastq.gz \
  --outdir mag-ont_output
```
# Output
