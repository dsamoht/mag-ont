process CHECKM {

    tag "group_${meta}"

    container params.checkm_container

    input:
    tuple val(meta), path(bins, stageAs: "bins/*")

    output:
    tuple val(meta), path("checkm_qa.tsv"), emit: checkm_stats, optional: true

    script:
    """
    checkm lineage_wf \
        -t ${task.cpus} \
        -x fa \
        --tab_table \
        -f checkm_qa.tsv \
        bins/ \
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm: \$( checkm 2>&1 | grep '...:::' | sed 's/.*CheckM v//;s/ .*//' )
    END_VERSIONS
    """
}
