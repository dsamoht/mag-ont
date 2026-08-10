process MULTIQC {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.31--pyhdfd78af_0' :
        'biocontainers/multiqc:1.31--pyhdfd78af_0' }"

    input:
    path multiqc_files, stageAs: "?/*"
    path(multiqc_config)
    path(extra_multiqc_config)
    path(multiqc_logo)

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , emit: plots, optional: true
    path "versions.yml"        , emit: versions

    script:
    def args      = task.ext.args ?: ''
    def config    = multiqc_config ? "--config $multiqc_config" : ''
    def extra     = extra_multiqc_config ? "--config $extra_multiqc_config" : ''
    def logo      = multiqc_logo ? "--cl-config 'custom_logo: \"${multiqc_logo}\"'" : ''
    """
    multiqc \\
        --force \\
        ${args} \\
        ${config} \\
        ${extra} \\
        ${logo} \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}
