#!/usr/bin/env bash
#
# Refuse to commit the output of a pipeline run.
#
# .gitignore covers the directories the test profiles write to (results/, work/,
# tests/mag-ont_out/, null/), but a run started with `--outdir <anything>` lands
# somewhere .gitignore has never heard of. This looks at what is actually staged
# and rejects the files a run leaves behind, whatever the directory is called.

set -euo pipefail

staged=$(git diff --cached --name-only --diff-filter=AM)
[ -n "$staged" ] || exit 0

# Signatures of a pipeline run: the versions file and execution reports written to
# <outdir>/pipeline_info, the per-group result directories, and Nextflow's own logs.
offenders=$(printf '%s\n' "$staged" | grep -E \
    -e '(^|/)pipeline_info/(execution_(report|timeline|trace)|pipeline_dag)' \
    -e '(^|/)pipeline_info/mag-ont_software_mqc_versions\.yml$' \
    -e '(^|/)group_[^/]+/(longread_qc|assembly|binning)/' \
    -e '(^|/)\.nextflow\.log' \
    -e '(^|/)work/[0-9a-f]{2}/[0-9a-f]{30}' \
    || true)

if [ -n "$offenders" ]; then
    echo "error: these staged files look like the output of a pipeline run:" >&2
    printf '  %s\n' $offenders >&2
    echo >&2
    echo "Results belong in --outdir, not in the repository. Unstage them with" >&2
    echo "  git restore --staged <path>" >&2
    echo "and add the directory to .gitignore if you will keep running there." >&2
    exit 1
fi
