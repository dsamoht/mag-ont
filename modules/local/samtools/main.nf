process SAMTOOLS {

    label 'process_low'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.18--h50ea8bc_1' :
        'biocontainers/samtools:1.18--h50ea8bc_1' }"

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path('*.bam'), path('*.bam.bai'), emit: bam_pair
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def output_bam = "${prefix}.bam"
    """
    samtools view ${args} -@ ${task.cpus} -bS ${sam} | \
    samtools sort ${args2} -@ ${task.cpus} -o ${output_bam} -
    samtools index ${output_bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
