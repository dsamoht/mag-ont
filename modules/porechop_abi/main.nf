process PORECHOP_ABI {

    tag "${meta.sample_id}"

    container params.porechop_abi_container

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads
    tuple val(meta), path("*.log"), emit: log
    path "versions.yml", emit: versions

    script:
    """
    porechop_abi \
        --ab_initio \
        --discard_middle \
        -i ${reads} \
        -o ${meta.sample_id}.porechopped.fastq.gz > ${meta.sample_id}.porechop.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        porechop_abi: \$( porechop_abi --version )
    END_VERSIONS
    """
}
