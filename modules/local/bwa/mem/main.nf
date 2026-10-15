process BWA_MEM {

    label 'process_medium'

    tag "${meta_reads.ref}:${meta_reads.id}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:8f3ad900103a4eb7fde71bb8b4841b1f18683f3f-0' :
        'biocontainers/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:8f3ad900103a4eb7fde71bb8b4841b1f18683f3f-0' }"

    input:
    tuple val(meta_reads), path(reads)
    tuple val(meta_ref)  , path(index)

    output:
    tuple val(meta_reads), path("*.bam"), path("*.bam.bai"), emit: bam_pair
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta_reads.id}"
    // samtools sort takes up to 4 of the task's threads, and 40% of its memory split between them
    def sort_threads = Math.min(4, task.cpus as int)
    def sort_mem = task.memory ? "-m ${((task.memory.toMega() * 0.4) / sort_threads) as int}M" : ''
    """
    bwa-mem2 mem \
        ${args} \
        -t $task.cpus \
        ${index}/${meta_ref.id} \
        ${reads[0]} \
        ${reads[1]} \
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
        bwa-mem2: \$(echo \$(bwa-mem2 version 2>&1 | tail -1))
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
