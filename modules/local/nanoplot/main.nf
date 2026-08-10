process NANOPLOT {

    label 'process_low'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanoplot:1.46.1--pyhdfd78af_0' :
        'biocontainers/nanoplot:1.46.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("*.html")                 , emit: html
    tuple val(meta), path("*.png") , optional: true , emit: png
    tuple val(meta), path("*.txt")                  , emit: txt
    path  "versions.yml"                            , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    NanoPlot \
        ${args} \
        -p ${prefix}_ \
        --fastq $fastq \
        -t $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(echo \$(NanoPlot --version 2>&1) | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
    """
}
