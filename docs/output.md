# dsamoht/mag-ont: Output

## Introduction

This document describes the output produced by the pipeline. Results are organised by
group: every directory below sits under `<outdir>/group_<group>/`, except the MultiQC
report and the pipeline information, which are global.

## Pipeline overview

- [Read QC](#read-qc) — NanoPlot, Porechop_ABI, Chopper
- [Assembly](#assembly) — Flye (optionally polished with Medaka) or metaMDBG
- [Gene prediction](#gene-prediction) — Pyrodigal
- [Mapping and coverage](#mapping-and-coverage) — minimap2 or bwa-mem2, samtools, CoverM
- [Binning](#binning) — MetaBAT2, MaxBin2, CONCOCT, SemiBin2, refined with DAS Tool
- [Bin quality and taxonomy](#bin-quality-and-taxonomy) — CheckM2, GTDB-Tk, MAG summary
- [MultiQC](#multiqc)
- [Pipeline information](#pipeline-information)

### Read QC

<details markdown="1">
<summary>Output files</summary>

- `group_<group>/reads/post_qc/`
  - `*.choppered.fastq.gz`: reads after adapter removal and length/quality filtering.
- `group_<group>/quality_assessment/nanoplot/raw/<sample>/`
  - `*.html`: read length and quality report before trimming.
- `group_<group>/quality_assessment/nanoplot/post_qc/<sample>/`
  - `*.html`: the same report after trimming.
- `group_<group>/quality_control/porechop/`
  - `*.porechop.log`: adapters found and removed.

</details>

Long reads are trimmed of adapters with Porechop_ABI, then filtered by length
(`--chopper_minlength`) and mean quality (`--chopper_minq`) with Chopper. Samples that
come with a pre-existing assembly skip QC.

### Assembly

<details markdown="1">
<summary>Output files</summary>

- `group_<group>/assembly/<assembler>/`
  - `*.assembly.fasta`: the assembly.
  - `*.assembly_graph.gfa`: assembly graph.
  - `*.assembly_info.txt`: per-contig statistics.
  - `*.flye.log`: assembler log.
- `group_<group>/assembly/medaka/`
  - `*.consensus.fasta`: the Medaka-polished assembly, used for binning when present.
    Flye with `--skip_medaka false` only; there is no such directory otherwise.
- `group_<group>/assembly/provided/`
  - the assembly supplied in the sample sheet, when one was given.

</details>

All long reads of a group are concatenated and assembled together. Medaka is skipped by
default, so the Flye assembly goes straight to binning and there is no `medaka/` directory.
With `--skip_medaka false` the assembly is polished, the polished consensus is what
downstream binning uses, and the unpolished assembly is published alongside it. metaMDBG is
never polished: its own consensus goes straight to binning.

### Gene prediction

<details markdown="1">
<summary>Output files</summary>

- `group_<group>/assembly/pyrodigal/`
  - `*.gff`: gene coordinates.
  - `*.fna`: nucleotide sequences of the predicted genes.
  - `*.faa`: protein sequences of the predicted genes.

</details>

Large assemblies are split into 100 MB chunks, annotated in parallel and merged back in
chunk order.

### Mapping and coverage

<details markdown="1">
<summary>Output files</summary>

- `group_<group>/mapping/samtools/`
  - `*.bam`, `*.bam.bai`: sorted, indexed alignments, one per sample.
- `group_<group>/mapping/coverm/`
  - `coverm_contig_stats.tsv`: mean, trimmed mean and covered fraction per contig.
- `group_<group>/mapping/genes/`
  - `gene_abund_norm.tsv`: contig coverage normalised to gene-level abundance.

</details>

When any sample of a group has short reads, they are mapped with bwa-mem2; otherwise the
long reads are mapped with minimap2.

### Binning

<details markdown="1">
<summary>Output files</summary>

- `group_<group>/binning/metabat/`
  - `metabat_bin.*.fa`, `*_depth.txt`
- `group_<group>/binning/maxbin/`
  - `maxbin_bin.*.fasta`, abundance files
- `group_<group>/binning/concoct/`
  - `concoct_*.fa`
- `group_<group>/binning/semibin/`
  - `*.fa`
- `group_<group>/binning/contig2bin/`
  - `*_contig2bin.tsv`: contig-to-bin assignment per binner.
- `group_<group>/binning/dastool/`
  - `*.fa`: the non-redundant set of bins selected by DAS Tool.
- `group_<group>/binning/coverm/`
  - `coverm_genome_stats.tsv`, `coverm_genome_stats_norm.tsv`: per-bin coverage.

</details>

Up to four binners run on the same assembly and coverage data; DAS Tool then selects the
best, non-redundant set of bins. Individual binners can be turned off with
`--skip_maxbin`, `--skip_concoct` and `--skip_semibin`.

### Bin quality and taxonomy

<details markdown="1">
<summary>Output files</summary>

- `group_<group>/binning/checkm/`
  - `quality_report.tsv`: completeness and contamination of each bin.
- `group_<group>/binning/single_contig_mags/<contig>/`
  - `quality_report.tsv`: CheckM2 assessment of contigs long enough to be a MAG on their
    own (see `--sc_mag_minimum`).
- `group_<group>/binning/gtdbtk/`
  - `gtdbtk.*.summary.tsv`: GTDB taxonomy of each bin.
- `group_<group>/binning/summary/`
  - `*_mag_summary.csv`: quality, coverage and taxonomy of every MAG in one table, one row per
    bin, columns in this order:
    - `bin_id`, `group_id`, `bin_filename`: the id given to the MAG by the pipeline, its group,
      and the bin file it was built from.
    - `completeness`, `contamination`, `genome_size`, `contig_n50`, `gc_content`,
      `total_contigs`, `max_contig_length`: CheckM2.
    - `domain`, `phylum`, `class`, `order`, `family`, `genus`, `species`: the GTDB-Tk
      classification split by rank, `Unclassified` for the ranks GTDB-Tk left unassigned.
    - `closest_placement_reference`, `closest_placement_ani`, `warnings`: GTDB-Tk. Empty under
      `--skip_gtdbtk`, as are the seven ranks above.
    - one `<sample>_mean`, `<sample>_trimmed_mean` and `<sample>_covered_fraction` per sample
      mapped to the group: CoverM, un-normalized.
    - `checkm_notes`: CheckM2 caveats on the prediction, empty when there are none.
  - `*_contig2bin.csv`: final contig-to-bin assignment.

</details>

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a single report aggregating read QC, bin quality and coverage.
  - `multiqc_data/`: parsed statistics behind the report.

</details>

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - `software_versions.yml`: versions of every tool that ran.
  - `execution_report_*.html`, `execution_timeline_*.html`, `execution_trace_*.txt`,
    `pipeline_dag_*.html`: Nextflow run reports.

</details>
