process HMMER_SUMMARY {

    conda "conda-forge::pandas=2.2.1"
    if (workflow.containerEngine == 'singularity') {
        container = params.pandas_singularity
    } else {
        container = params.pandas_docker
    }

    publishDir "${params.outdir}/hmmer", mode: 'copy'

    input:
    tuple val(meta), path(hmmerTable)
    path koList
    tuple val(meta), path(diamond_result)

    output:
    tuple val(meta), path('genes_annot_summary.tsv'), emit: hmmerSummary

    script:
    """
    genes_annot_summary.py -t ${hmmerTable} -l ${koList} -d ${diamond_result}
    """
}