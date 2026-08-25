# dsamoht/mag-ont: Usage

## Introduction

mag-ont assembles and bins metagenomes from Oxford Nanopore long reads, optionally using
paired-end short reads for the coverage signal during binning. Samples are processed in
**groups**: every sample sharing a `group` value is co-assembled and binned together.

## Samplesheet input

Pass a comma-separated file with six columns to `--input`.

```bash
--input '[path to samplesheet file]'
```

### Full samplesheet

```csv title="samplesheet.csv"
sample_id,group,assembly_fasta,long_reads,short_reads_1,short_reads_2
sample1,groupA,,/data/sample1.ont.fastq.gz,,
sample2,groupB,/data/groupB.assembly.fasta,/data/sample2.ont.fastq.gz,,
sample3,groupC,/data/groupC.assembly.fasta,/data/sample3.ont.fastq.gz,/data/sample3_R1.fastq.gz,/data/sample3_R2.fastq.gz
sample4,groupC,/data/groupC.assembly.fasta,/data/sample4.ont.fastq.gz,/data/sample4_R1.fastq.gz,/data/sample4_R2.fastq.gz
```

| Column           | Description                                                                                                                     |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `sample_id`      | Unique sample identifier. Spaces are not allowed.                                                                               |
| `group`          | Samples sharing a group are assembled and binned as one unit. Spaces are not allowed.                                           |
| `assembly_fasta` | Optional pre-existing assembly. When given, the group is not assembled and every row of that group must point at the same file. |
| `long_reads`     | Gzipped FastQ file of nanopore reads. Required unless `assembly_fasta` is given.                                                |
| `short_reads_1`  | Optional gzipped FastQ file of forward paired-end reads.                                                                        |
| `short_reads_2`  | Optional gzipped FastQ file of reverse paired-end reads. Required if `short_reads_1` is set.                                    |

Rules that apply across the rows of a group, checked before any task is submitted:

- A group needs either long reads to assemble or a pre-existing assembly.
- All rows of a group must reference the same `assembly_fasta`, or none of them.
- A read file cannot be shared by two samples of the same group.
- A group cannot mix long-read-only samples with short-read-only samples, because the
  mapping strategy is chosen once per group.

When any sample of a group carries short reads, those reads drive the coverage signal for
binning; otherwise the long reads are mapped with minimap2.

## Running the pipeline

```bash
nextflow run dsamoht/mag-ont -profile docker --input ./samplesheet.csv --outdir ./results
```

Results, work directory and Nextflow cache are written to the current directory.

### Updating the pipeline

```bash
nextflow pull dsamoht/mag-ont
```

### Reproducibility

Specify the pipeline version with `-r`, and record it in your methods:

```bash
nextflow run dsamoht/mag-ont -r 1.4.0 -profile docker --input ./samplesheet.csv --outdir ./results
```

## Core Nextflow arguments

### `-profile`

Use one of the container profiles rather than installing the tools yourself. Profiles are
comma-separated and order matters, the last one wins.

- `docker`, `singularity`, `apptainer`, `podman`, `shifter`, `charliecloud`, `wave`
- `conda` / `mamba` — only if none of the container engines are available, and only together with
  `--skip_bin_qa`: CheckM2 needs a DIAMOND reference database that the pipeline supplies through
  its container image, and the Bioconda package ships none, so `CHECKM` fails without it
- `gpu` — passes the GPU through to Medaka and SemiBin2
- `drac` — slurm executor and resources for Digital Research Alliance of Canada clusters
- `test` — a minimal dataset that exercises the whole pipeline
- `test_full` — full-size test

### `-resume`

Restart a previous run, reusing the tasks whose inputs have not changed.

## Pipeline specific options

| Option                | Default                       | Description                                                                                        |
| --------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------- |
| `--assembler`         | `flye`                        | Long read assembler, `flye` or `metamdbg`.                                                         |
| `--medaka_model`      | `r1041_e82_400bps_hac_v5.2.0` | Flye only, and only with `--skip_medaka false`. Must match the flow cell, kit and basecaller used. |
| `--chopper_minlength` | `1000`                        | Minimum read length kept by Chopper.                                                               |
| `--chopper_minq`      | `10`                          | Minimum average read quality kept by Chopper.                                                      |
| `--only_qc`           | `false`                       | Stop after long read QC, before assembly.                                                          |
| `--maxbin_minlen`     | `2500`                        | Minimum contig length considered by MaxBin2.                                                       |
| `--sc_mag_minimum`    | `500000`                      | Contigs at least this long are assessed as single-contig MAGs.                                     |
| `--gtdbtk_db`         | `null`                        | Local GTDB-Tk database, required unless `--skip_gtdbtk` is set.                                    |

`--only_qc` stops the run after long read QC: NanoPlot, Porechop_ABI and Chopper run, the
QC'd reads and the MultiQC report are published, and no assembly, annotation, mapping or
binning task is submitted. Samples that come with their own assembly do not go through read
QC, so nothing runs for them. It cannot be combined with `--skip_qc`, which would leave
nothing to run.

Any step can be turned off: `--skip_qc`, `--skip_nanoplot`, `--skip_porechop`,
`--skip_medaka`, `--skip_maxbin`, `--skip_concoct`, `--skip_semibin`, `--skip_bin_qa`,
`--skip_gtdbtk`, `--skip_multiqc`. All default to `false` except `--skip_medaka`.

Medaka polishes Flye assemblies only, and is **skipped by default**. Medaka is a haploid
consensus model: on a co-assembly of related organisms at uneven depth it can replace a low
coverage genome's sequence with that of a high coverage relative, and with R10.4.1 reads the
accuracy it buys is small. Pass `--skip_medaka false` to polish anyway, and check that
`--medaka_model` matches the basecaller — a mismatched model makes the assembly worse.

metaMDBG produces its own consensus, so no polishing step runs with `--assembler metamdbg`,
and passing `--medaka_model` or `--skip_medaka` on the command line together with it stops
the run.

## Custom configuration

### Resource requests

Resource requests are set per process label in `conf/base.config`. To change them for one
process, supply your own config with `-c`:

```groovy title="custom.config"
process {
    withName: 'FLYE' {
        memory = 200.GB
        time   = 48.h
    }
}
```

### Custom containers or tool arguments

Tool flags come from `ext.args` in `conf/modules.config`, so they can be overridden the
same way:

```groovy title="custom.config"
process {
    withName: 'MINIMAP' {
        ext.args = '-ax lr:hq'
    }
}
```

## Running in the background

```bash
nextflow run dsamoht/mag-ont -profile docker --input ./samplesheet.csv --outdir ./results -bg
```

## Nextflow memory requirements

Add the following to `~/.bashrc` to cap the memory the Nextflow JVM takes:

```bash
export NXF_OPTS='-Xms1g -Xmx4g'
```
