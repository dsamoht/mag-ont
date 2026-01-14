process MINIMAP {

    tag "${meta_reads.sample_id}"
    container params.minimap_container

    input:
    tuple val(meta_reads), path(reads)
    tuple val(meta_reference), path(reference)

    output:
    tuple val(meta_reads), path('*.sam'), emit: sam
    path("versions.yml"), emit: versions

    script:
    def output_sam = "${meta_reads.sample_id}.sam"
    """
    minimap2 \
        -ax map-ont \
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
