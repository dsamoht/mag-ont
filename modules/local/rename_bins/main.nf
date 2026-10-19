process RENAME_BINS {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils@sha256:f0cad0d32d8d8fac7bb971736f158200cf19b4817dd796bd9d76240a054bacf2"

    input:
    tuple val(meta), path(bins, stageAs: "bins/*")

    output:
    tuple val(meta), path("*_bin_*.fa", arity: '1..*'), emit: bins
    tuple val(meta), path("*_bin_names.csv")          , emit: bin_names
    path "versions.yml"                               , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Bins are numbered in byte order of their file names
    """
    echo "bin_id,original_bin" > ${prefix}_bin_names.csv
    i=0
    for bin in \$(LC_ALL=C ls bins); do
        i=\$((i + 1))
        name=\$(printf '${prefix}_bin_%03d' \$i)
        cp "bins/\$bin" "\$name.fa"
        echo "\$name,\$bin" >> ${prefix}_bin_names.csv
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coreutils: \$(cp --version | head -n 1 | sed 's/.* //')
    END_VERSIONS
    """
}
