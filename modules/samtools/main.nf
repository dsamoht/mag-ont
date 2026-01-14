process SAMTOOLS {

    tag "${meta.sample_id}"

    container params.samtools_container

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path('*.bam'), path('*.bam.bai'), emit: bam_pair
    path("versions.yml"), emit: versions

    script:
    def output_bam = "${meta.sample_id}.bam"
    """
    samtools view -@ ${task.cpus} -bS ${sam} | \
    samtools sort -@ ${task.cpus} -o ${output_bam} -
    samtools index ${output_bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
