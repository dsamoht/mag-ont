process FILTER_HQ_SC {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils@sha256:f0cad0d32d8d8fac7bb971736f158200cf19b4817dd796bd9d76240a054bacf2"

    input:
    tuple val(meta), path(contigs), path(checkm_tsv)
    val threshold

    output:
    tuple val(meta), path("hq_contigs/*.fa"), emit: hq_sc, optional: true
    tuple val(meta), path("lq_contigs/*.fa"), emit: lq_sc, optional: true
    path "versions.yml"                     , emit: versions

    script:
    """
    mkdir -p hq_contigs lq_contigs

    filter_hq_sc.py \\
        --checkm ${checkm_tsv} \\
        --hq-dir hq_contigs \\
        --lq-dir lq_contigs \\
        --threshold ${threshold} \\
        ${contigs}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
    END_VERSIONS
    """
}
