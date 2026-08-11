# mag-ont: Contributing

Contributions are welcome. This pipeline follows the
[nf-core](https://nf-co.re) template conventions without being an nf-core pipeline;
`.nf-core.yml` records every deliberate deviation and the reason for it.

## Getting started

`main` holds released code and `dev` is the development branch. Branch off `dev`, and open
pull requests against `dev` — only releases are merged into `main`.

## Requirements

- Nextflow `>=26.04.0`
- Docker or Singularity (Conda is not supported for the CheckM2 step, see below)
- [nf-test](https://www.nf-test.com) 0.9.x
- [pre-commit](https://pre-commit.com)
- [nf-core/tools](https://github.com/nf-core/tools) 4.1.0, for linting

## Before opening a pull request

```bash
pre-commit run --all-files                # prettier, whitespace, nextflow-lint
nf-core pipelines lint                    # template compliance
nf-test test --profile=+docker tests/default.nf.test
```

If a change alters what the pipeline publishes, the pipeline snapshot has to be regenerated
and committed with the change:

```bash
nf-test test --profile=+docker --update-snapshot tests/default.nf.test
```

CI runs the same tests over docker and singularity on the pinned Nextflow version, and
non-blocking on `latest-everything`. Note that a `latest-everything` job reports green even
when its test fails — it is marked `continue-on-error`, so read its log rather than its badge.

## Conventions

Both are described in more detail in `CLAUDE.md` at the repository root.

- **Modules** live in `modules/local/<tool>[/<subtool>]/` with `main.nf`, `environment.yml` and
  `meta.yml`. Tool flags belong in `conf/modules.config` as `ext.args`, never in the module.
- **Publishing** is declared only in the `output {}` block of `main.nf`. There are no
  `publishDir` directives anywhere in the pipeline.
- **New parameters** need a default in `nextflow.config`, an entry in the matching `$defs`
  section of `nextflow_schema.json`, and a mention in `docs/usage.md`.
- **Channels** fan in with `groupKey(group, size)` rather than a bare `groupTuple`, so a group
  is released as soon as its own tasks finish.

## Conda support

CheckM2 needs a DIAMOND reference database. The pipeline supplies it through the
`docker.io/dsamoht/checkm2` image, and the Bioconda package ships no database, so the `CHECKM`
process fails under `-profile conda` with `DIAMOND database not found`. Conda works for runs
that skip bin QA (`--skip_bin_qa`); use Docker or Singularity otherwise.
