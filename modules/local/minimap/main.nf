process MINIMAP {

    label 'process_medium'

    tag "${meta_reads.ref}:${meta_reads.id}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:eb7d926a9d7da1ab8e5427cd947dbbb8795eabab-0' :
        'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:eb7d926a9d7da1ab8e5427cd947dbbb8795eabab-0' }"

    input:
    tuple val(meta_reads), path(reads)
    tuple val(meta_reference), path(reference)

    output:
    tuple val(meta_reads), path('*.bam'), path('*.bam.bai'), emit: bam_pair
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta_reads.id}"
    // samtools sort takes up to 4 of the task's threads, and 40% of its memory split between them
    def sort_threads = Math.min(4, task.cpus as int)
    def sort_mem = task.memory ? "-m ${((task.memory.toMega() * 0.4) / sort_threads) as int}M" : ''
    """
    minimap2 \
        ${args} \
        -t $task.cpus \
        ${reference} \
        ${reads} \
        | samtools sort \
            ${args2} \
            -@ ${sort_threads} \
            ${sort_mem} \
            -T ${prefix}.sort_tmp \
            --write-index \
            -o ${prefix}.bam##idx##${prefix}.bam.bai \
            -

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
