process DASTOOL_CONTIG2BIN {

    label "small"

    tag "group_${meta}_${software}"

    container params.pandas_container

    publishDir "${params.outdir}/group_${meta}/binning/dastool", mode: "copy"

    input:
    tuple val(meta), val(software), path(bins, stageAs: "input_bins/*")

    output:
    tuple val(meta), path("*_contig2bin.tsv"), emit: contig2bin, optional: true

    script:
    """
    dastool_contig2bin.py ./input_bins ${software}
    """
}
