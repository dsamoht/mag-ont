process FILTER_HQ_SC {

    label "small"

    tag "group_${meta.group}"
    
    container params.python_container

    input:
    tuple val(meta), path(bins), path(checkm_tsv)

    output:
    tuple val(meta), path("hq_contigs/*.fa"), emit: hq_sc, optional: true
    tuple val(meta), path("lq_contigs/*.fa"), emit: lq_sc, optional: true

    script:
    """
    mkdir -p hq_contigs lq_contigs
    
    filter_hq_sc.py \\
        --checkm ${checkm_tsv} \\
        --hq-dir hq_contigs \\
        --lq-dir lq_contigs \\
        --threshold 90.0 \\
        ${bins}
    """
}
