# mag-ont: Changelog

All notable changes to this pipeline are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and the project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-08-11

### Added

- Single-contig MAGs: contigs longer than `--sc_mag_minimum` are split out of the assembly,
  assessed once per group with CheckM2, and those above `--sc_mag_min_completeness` are held out
  of binning and added back to the final bin set. Rejected candidates rejoin the assembly the
  binners see, with their original headers restored. The step is skipped under `--skip_bin_qa`.
- `metaMDBG` as an alternative long-read assembler alongside Flye.

### Changed

- **Nextflow `>=26.04.0` is now required.** nf-schema 2.8.0 does not load on earlier versions.
- nf-schema updated to 2.8.0, and `PIPELINE_INITIALISATION` restructured to follow the nf-core
  template: help is rendered with `paramsHelp()` rather than `validation.help.enabled`.
- Publishing moved entirely into the `output {}` block of `main.nf`; no `publishDir` directives
  remain in the pipeline.
- The `bio-utils` container is pinned by sha256 digest.

### Fixed

- `--help` produced no output on Nextflow 25.10+, because the pinned nf-schema 2.5.1 did not
  recognise `validation.help.showHiddenParameter` and then failed validation.
- The pipeline now fails immediately when `--outdir` is not set, instead of silently publishing
  to `./results`. `params.outdir` is checked in `PIPELINE_INITIALISATION` as well as by the
  schema, so the check survives `--validate_params false`.
- `--help` and `--version` no longer create a `null/` directory in the launch directory.

## [1.3.1] - 2026-06-22

### Added

- End-to-end pipeline test under `--skip_bin_qa`.

### Changed

- Pyrodigal processes large assemblies in 100 MB chunks.
- DAS_Tool is given an explicit `--threads` option.

## [1.3.0] - 2026-06-19

### Added

- nf-test pipeline test, run from GitHub Actions.
- Workflow output declarations.

### Changed

- Reorganised the test data directory.

## [1.2.2] - 2026-03-23

### Fixed

- Corrected the version reported in the docstring.

## [1.2.1] - 2026-03-20

### Fixed

- NanoPlot results no longer overwrite one another when published.

## [1.2.0] - 2026-03-11

### Added

- Pyrodigal gene calling, and CoverM normalisation by mapped-nucleotide depth.
- Configurable Medaka model with a default.

### Fixed

- Publishing of the Porechop_ABI log and the SemiBin2 results.

## [1.0.0] - 2025-12-18

Initial release: long-read QC, per-group co-assembly, binning with several binners, DAS_Tool
refinement, and bin quality and taxonomy assignment.

[1.4.0]: https://github.com/dsamoht/mag-ont/releases/tag/v1.4.0
[1.3.1]: https://github.com/dsamoht/mag-ont/releases/tag/v1.3.1
[1.3.0]: https://github.com/dsamoht/mag-ont/releases/tag/v1.3.0
[1.2.2]: https://github.com/dsamoht/mag-ont/releases/tag/v1.2.2
[1.2.1]: https://github.com/dsamoht/mag-ont/releases/tag/v1.2.1
[1.2.0]: https://github.com/dsamoht/mag-ont/releases/tag/v1.2.0
[1.0.0]: https://github.com/dsamoht/mag-ont/releases/tag/v1.0.0
