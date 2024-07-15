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
    hmmerTablePfam = hmmerTable.grep(~/.*pfam.*/)
    hmmerTableKegg = hmmerTable.grep(~/.*kegg.*/)
    if(hmmerTablePfam.isEmpty()) {
        hmmerTablePfam = hmmerTablePfam.join('')
    } else {
        hmmerTablePfam = '-p ' + hmmerTablePfam.join('')
    }
    if(hmmerTableKegg.isEmpty()) {
        hmmerTableKegg = hmmerTableKegg.join('')
    } else {
        hmmerTableKegg = '-k ' + hmmerTableKegg.join('')
    }
    """
    genes_annot_summary.py ${hmmerTablePfam} ${hmmerTableKegg} -l ${koList} -d ${diamond_result}
    """
}