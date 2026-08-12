process CHECKM {

    label 'process_high'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/checkm2:1.1.0"

    input:
    tuple val(meta), path(bins, stageAs: "bins/*")

    output:
    tuple val(meta), path("checkm2_out/quality_report.tsv"), emit: checkm_stats, optional: true
    path("versions.yml")                                   , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    checkm2 predict \\
        ${args} \\
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
