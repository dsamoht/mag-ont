process PREPARE_STEP2 {

    publishDir "${params.step2_inputDir}/${meta['name']}", mode: 'copy'

    input:
    tuple val(meta), path(genes)
    tuple val(meta), path(annotation)
    tuple val(meta), path(abundance)

    output:
    tuple val(meta), path("${meta['name']}_genes.faa")
    tuple val(meta), path("${meta['name']}_genes_annot_summary.tsv")
    tuple val(meta), path("${meta['name']}_genes_abundance.tsv")

    script:
    """
    cp ${genes} ${meta['name']}_genes.faa
    cp ${annotation} ${meta['name']}_genes_annot_summary.tsv
    cp ${abundance}  ${meta['name']}_genes_abundance.tsv
    """
}