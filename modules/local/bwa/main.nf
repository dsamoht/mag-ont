process BWA_MEM {

    label 'process_medium'

    tag "$meta_reads.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bwa-mem2:2.3--he70b90d_0' :
        'biocontainers/bwa-mem2:2.3--he70b90d_0' }"

    input:
    tuple val(meta_reads), path(reads)
    tuple val(meta_ref)  , path(reference)

    output:
    tuple val(meta_reads), path("*.sam"), emit: sam
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta_reads.id}"
    def output_sam = "${prefix}.sam"
    """
    PREFIX=${prefix}_index
    bwa-mem2 index \
        -p \$PREFIX \
        ${reference}

    bwa-mem2 mem \
        ${args} \
        -t $task.cpus \
        \$PREFIX \
        ${reads[0]} \
        ${reads[1]} \
        > ${output_sam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa-mem2: \$(echo \$(bwa-mem2 version 2>&1 | tail -1))
    END_VERSIONS
    """
}
