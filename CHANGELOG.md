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
- `--help` no longer leaves a `null/` directory and an empty `work/` directory behind in the
  directory it was called from. The execution reports are only enabled once `--outdir` is
  known, which also silences the `Failed to render execution report` warnings, and the empty
  work directory Nextflow creates at start-up is removed again before the help message exits.

### `Changed`

- The seven modules that run the `dsamoht/bio-utils` image now pin it by digest instead of
  the mutable `:latest` tag, so a rerun always gets the same image and the Docker and Conda
  paths cannot drift apart.
- `nf-schema` is pinned to `2.8.0`, and the help message is now built with `paramsHelp()`
  in `PIPELINE_INITIALISATION` as the nf-core template does, instead of the
  `validation.help.enabled` config option (which printed nothing at all under the
  previously pinned `2.5.1` on Nextflow 25.10+).
- `nextflow_schema.json` follows the nf-core template layout again: the parameters of the
  features this pipeline does not use (`email`, `email_on_fail`, `plaintext_email`,
  `hook_url`) are gone, and the MultiQC parameters are back in `Generic options`.
- Channel synchronisation: `groupKey()` releases each group as soon as its own samples
  finish, rather than waiting for every group; gene predictions are passed to the
  binning subworkflow separately so mapping no longer waits for Pyrodigal; and the
  redundant `groupTuple()` after the MaxBin join was removed.

## v1.4.0

Initial versioned release.
