process MAXBIN_ABUND {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils@sha256:f0cad0d32d8d8fac7bb971736f158200cf19b4817dd796bd9d76240a054bacf2"

    input:
    tuple val(meta), path(metabat_depth)

    output:
    tuple val(meta), path("maxbin_abund.txt"), emit: maxbin_abund
    path "versions.yml", emit: versions

    script:
    """
    maxbin_abund_from_metabat_depth.py \
        ${metabat_depth}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
        pandas: \$(python3 -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
