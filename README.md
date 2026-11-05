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
     Version: v1.5.2
```

## workflow

```mermaid
flowchart TD
    lr[/"nanopore reads"/]
    sr[/"short reads<br/>(optional)"/]
    asm_in[/"assembly<br/>(optional)"/]

    subgraph qc ["Long-read QC · per sample"]
        porechop["Porechop_ABI<br/>adapter removal"] --> chopper["Chopper<br/>length + quality filter"]
        nanoplot["NanoPlot<br/>before + after"]
    end

    subgraph assembly ["Co-assembly · per group"]
        assembler["Flye (+ Medaka)<br/>or metaMDBG"] --> asm["assembly"]
    end

    subgraph scmag ["Single-contig MAGs"]
        is_long{"contig ≥ 500 kb?"}
        checkm_sc["CheckM2"]
        is_complete{"completeness ≥ 90 %?"}
        sc["single-contig MAGs"]
        to_bin["contigs to bin"]
        is_long -- yes --> checkm_sc --> is_complete
        is_long -- no --> to_bin
        is_complete -- no --> to_bin
        is_complete -- yes --> sc
    end

    subgraph binning ["Binning · per group"]
        mapping["minimap2 or BWA-MEM<br/>reads vs. full assembly"]
        metabat["MetaBAT2"]
        comebin["COMEBin"]
        semibin["SemiBin2"]
        dastool["DAS_Tool"]
        mapping -- depth --> metabat & comebin & semibin
        metabat & comebin & semibin --> dastool
    end

    subgraph evaluation ["MAG evaluation"]
        mags["final MAGs<br/>group_bin_NNN.fa"]
        coverm["CoverM<br/>abundance"]
        checkm["CheckM2<br/>quality"]
        gtdbtk["GTDB-Tk<br/>taxonomy"]
        summary["MAG summary"]
        mags --> coverm & checkm & gtdbtk --> summary
    end

    lr --> porechop
    lr -.-> nanoplot
    chopper -.-> nanoplot
    chopper --> assembler
    asm_in -. skips QC + assembly .-> asm
    asm --> is_long
    asm --> mapping
    chopper -- long reads --> mapping
    sr -- short reads --> mapping
    to_bin --> metabat & comebin & semibin
    dastool --> mags
    sc --> mags
    mapping -- BAMs --> coverm

    classDef optional stroke-dasharray: 5 5
    class porechop,nanoplot,comebin,semibin,checkm,gtdbtk optional
    style scmag stroke-dasharray: 5 5
```


## tl;dr
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
