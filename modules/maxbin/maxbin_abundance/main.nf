process MAXBIN_ABUND {

    label "small"

    tag "group_${meta}"

    container params.pandas_container

    input:
    tuple val(meta), path(metabat_depth)

    output:
    tuple val(meta), path("maxbin_abund.txt"), emit: maxbin_abund

    script:
    """
    maxbin_abund_from_metabat_depth.py \
        ${metabat_depth}
    """
}
