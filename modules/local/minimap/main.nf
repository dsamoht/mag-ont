process MINIMAP {

    label 'process_medium'

    tag "$meta_reads.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/minimap2:2.30--h577a1d6_0' :
        'biocontainers/minimap2:2.30--h577a1d6_0' }"

    input:
    tuple val(meta_reads), path(reads)
    tuple val(meta_reference), path(reference)

    output:
    tuple val(meta_reads), path('*.sam'), emit: sam
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta_reads.id}"
    def output_sam = "${prefix}.sam"
    """
    minimap2 \
        ${args} \
        -t $task.cpus \
        ${reference} \
        ${reads} \
        > ${output_sam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """
}
