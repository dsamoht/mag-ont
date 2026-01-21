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
tailored for Oxford Nanopore reads
     
     Github: https://github.com/dsamoht/mag-ont
     Version: v1.1.0
```
## Software dependencies
- [Nextflow](https://www.nextflow.io/)  
- [Docker](https://www.docker.com/) or [Apptainer (Singularity)](https://apptainer.org/)
## Database
  - [GTDB-Tk database - release 226](https://ecogenomics.github.io/GTDBTk/installing/index.html#gtdb-tk-reference-data) (uncompressed)

## Installation
Once the dependencies are installed, you can directly use the pipeline. You just have to choose a container engine and a workload capacity (test: 1 cpu, local : 8 cpus, hpc : 20 cpus). Profiles can be edited in [nextflow.config](./nextflow.config).  

```
nextflow run main.nf \
  -profile {docker/singularity},{test/local/hpc} \
  --gtdbtk_db /path/to/uncompressed/db \
  --input ./test_data/samplesheet.csv \
  --outdir ./test_data/test_out
```
