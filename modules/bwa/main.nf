process BWA_MEM {
    
    label "medium"
    
    tag "${meta_reads.sample_id}"

    container params.bwamem2_container

    input:
    tuple val(meta_reads), path(reads)
    tuple val(meta_ref)  , path(reference)

    output:
    tuple val(meta_reads), path("*.sam"), emit: sam
    path("versions.yml"), emit: versions

    script:
    def output_sam = "${meta_reads.sample_id}.sam"
    """
    PREFIX=group_${meta_ref}_index
    bwa-mem2 index \
        -p \$PREFIX \
        ${reference}

    bwa-mem2 mem \
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
