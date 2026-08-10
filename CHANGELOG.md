# dsamoht/mag-ont: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.5.0dev - [unreleased]

### `Added`

- The pipeline now follows nf-core conventions: modules live in `modules/local/` with
  `meta.yml` and `environment.yml`, tool flags are set through `ext.args` in
  `conf/modules.config`, and resources use the standard `process_*` labels.
- Parameter validation and sample sheet parsing with the `nf-schema` plugin
  (`nextflow_schema.json` and `assets/schema_input.json`).
- MultiQC report collecting NanoPlot, Porechop_ABI, CheckM2 and CoverM output.
- Standard container profiles (conda, mamba, docker, singularity, podman, shifter,
  charliecloud, apptainer, wave, gpu, arm64) plus `test_full`.
- Every module now emits `versions.yml`; the seven that did not are covered.

### `Fixed`

- `MAG_SUMMARY` never ran when `--skip_gtdbtk` was set, because the summary was built by
  joining an empty channel. The MAG summary and final contig2bin table were silently
  missing from the results.
- Pyrodigal's `gff`, `fna` and `faa` channels were joined on the group id, which is not
  unique once an assembly is split into more than one chunk, so annotations from
  different chunks could be paired together.
- The single-contig MAG branch could not run: the size filter tested the tuple rather
  than the FASTA file, `record.text` was never populated, and CheckM2 was handed a
  string instead of a file.
- `--medaka_model` was declared but never passed to Medaka, which always ran with its
  built-in default model.
- `MAG_SUMMARY` crashed for any group where DAS_Tool produced exactly one bin.

### `Changed`

- Channel synchronisation: `groupKey()` releases each group as soon as its own samples
  finish, rather than waiting for every group; gene predictions are passed to the
  binning subworkflow separately so mapping no longer waits for Pyrodigal; and the
  redundant `groupTuple()` after the MaxBin join was removed.

## v1.4.0

Initial versioned release.
