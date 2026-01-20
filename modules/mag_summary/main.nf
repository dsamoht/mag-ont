process MAG_SUMMARY {

    tag "group_${meta}"

    container params.pandas_container

    publishDir "${params.outdir}/group_${meta}/binning/summary", mode: 'copy'

    input:
    tuple val(meta), path(dastool_bins)
    tuple val(meta), path(checkm_stats)
    tuple val(meta), path(gtdbtk_res)
    tuple val(meta), path(coverm_stats)

    output:
    tuple val(meta), path("*_mag_summary.csv"), emit: mag_summary
    tuple val(meta), path("*_contig2bin.csv"), emit: contig2bin

    script:
    """
    gtdbtk_bac=""
    gtdbtk_ar=""

    for f in ${gtdbtk_res}; do
        if [[ \$f == *"bac120"* ]]; then gtdbtk_bac="--bac120 \$f"; fi
        if [[ \$f == *"ar53"* ]]; then gtdbtk_ar="--ar53 \$f"; fi
    done

    mag_summary.py \
        --bins ${dastool_bins.join(' ')} \
        --checkm ${checkm_stats} \
        --coverm ${coverm_stats} \
        \${gtdbtk_bac} \
        \${gtdbtk_ar} \
        --group group_${meta} \
        --output group_${meta}_mag_summary.csv
    """
}
