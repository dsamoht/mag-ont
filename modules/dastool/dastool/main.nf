process DASTOOL {

    tag "group_${meta}"

    container params.dastool_container

    input:
    tuple val(meta), path(assembly), path(contig2bin)

    output:
    tuple val(meta), path("das-bin*/*bin*.fa"), emit: dastool_bins, optional: true

    script:
    def contig2binList = contig2bin.join(",")
    def labels = contig2bin.collect { it.name.replaceAll(/_contigs?2bin\.tsv$/, "") }.join(",")
    """
    DAS_Tool \
        -i ${contig2binList} \
        -l ${labels} \
        -c ${assembly} \
        -o das-bin \
        --write_bins \
        --score_threshold=-9999

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dastool: \$( DAS_Tool --version 2>&1 | grep "DAS Tool" | sed 's/DAS Tool //' )
    END_VERSIONS
    """
}
