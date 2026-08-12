[![Nextflow](https://img.shields.io/badge/version-%E2%89%A526.04.0-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
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

## tl;dr

```bash
nextflow run main.nf --help # if working in the repo
```
or 
```bash
nextflow run dsamoht/mag-ont --help # nextflow pulls the repo automatically
```

## software dependencies

- Nextflow
- a container engine (i.e. docker/singularity) or conda

## database

- [GTDB-Tk database - release 226](https://ecogenomics.github.io/GTDBTk/installing/index.html#gtdb-tk-reference-data)

## documentation  
Full documentation: [usage](./docs/usage.md).  
Pipeline outputs: [output](./docs/output.md).  

## acknowledgement

This pipeline is inspired by [**nf-core/mag**](https://github.com/nf-core/mag) and [**HiFi-MAG-Pipeline by PacificBiosciences**](https://github.com/PacificBiosciences/pb-metagenomics-tools/tree/master/HiFi-MAG-Pipeline)
