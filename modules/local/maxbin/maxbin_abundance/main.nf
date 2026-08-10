process MAXBIN_ABUND {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils:latest"

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
