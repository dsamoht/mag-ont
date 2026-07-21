process CHECKM {

    label "large"

    tag "group_${meta}"

    container params.checkm_container

    input:
    tuple val(meta), path(bins, stageAs: "bins/*")

    output:
    tuple val(meta), path("checkm2_out/quality_report.tsv"), emit: checkm_stats, optional: true
    path("versions.yml")                                   , emit: versions

    script:
    """
    checkm2 predict \\
        --threads ${task.cpus} \\
        --input bins/ \\
        -x fa \\
        --output-directory checkm2_out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: \$(checkm2 --version)
    END_VERSIONS
    """
}
