process NANOPLOT {

    label "small"

    tag "${meta.sample_id}"

    container params.nanoplot_container

    publishDir "${params.outdir}/group_${meta.group}/reads_qc/nanoplot_${step}", mode: "copy"

    input:
    tuple val(meta), val(step), path(fastq)

    output:
    tuple val(meta), path("*.html")                 , emit: html
    tuple val(meta), path("*.png") , optional: true , emit: png
    tuple val(meta), path("*.txt")                  , emit: txt
    path  "versions.yml"                            , emit: versions

    script:
    """
    NanoPlot \
        --fastq $fastq \
        -t $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(echo \$(NanoPlot --version 2>&1) | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
    """
}
