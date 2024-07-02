process PREPARE_STEP2 {

    //publishDir params.outdir, mode: 'copy'

    input:
    tuple val(meta), path(genes)
    tuple val(meta), path(annotation)
    tuple val(meta), path(abundance)
    path step2_sheet

    output:
    tuple val(meta), path(step2_sheet), emit: step2Sheet

    script:
    """
    echo "${meta['name']}\t${params.outdir}" >> ${step2_sheet}
    """
}