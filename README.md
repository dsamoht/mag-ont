[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

```
                                         _   
 _ __ ___   __ _  __ _        ___  _ __ | |_ 
| '_ ` _ \ / _` |/ _` |_____ / _ \| '_ \| __|
| | | | | | (_| | (_| |_____| (_) | | | | |_ 
|_| |_| |_|\__,_|\__, |      \___/|_| |_|\__|
                 |___/                       

Workflow for genome assembly with Oxford Nanopore reads.
     
     Github: https://github.com/dsamoht/mag-ont
     Version: still no release

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
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
# Output example

| file | num_seqs | sum_len  | min_len | avg_len   | max_len  | Q1 | Q2 | Q3 | N50 | GC(%) | completeness | contamination | domain | phylum | class | order | family | genre | species | closest_placement_reference | closest_placement_ani |warnings |
|-------|----------|----------|---------|-----------|----------|---------|---------|---------|---------|-------|--------------|---------------|------------|-----------------|------------------|-------------------|------------------|----------------|--------------------------|-----------------------------|------------------------|-----------------------------------------------|
| bin.001.fa  | 6 | 5139974  | 6816    | 856662.3  | 4778146  | 27273.0 | 94520.5 | 138698.0| 4778146| 39.51 | 97.13        | 0.34          | d__Bacteria| p__Cyanobacteriota | c__Cyanobacteriia | o__Cyanobacteriales | f__Microcoleaceae | g__Planktothrix | s__Planktothrix agardhii | GCA_003609755.1             | 98.67                  | Genome;has;more;than;10.0%;of;markers;with;multiple;hits |