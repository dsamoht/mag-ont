process HMMER_SUMMARY {

    if (workflow.containerEngine == 'singularity') {
        container = params.pandas_singularity
    } else {
        container = params.pandas_docker
    }

    publishDir "${params.outdir}/hmmer", mode: 'copy'

    input:
    path hmmerDomTable
    path koList
    path diamond_result

    output:
    path 'contig_annotation.tsv', emit: hmmerSummary

    script:
    hmmerDomTablePfam = hmmerDomTable.grep(~/.*pfam.*/)
    hmmerDomTableKegg = hmmerDomTable.grep(~/.*kegg.*/)
    if(hmmerDomTablePfam.isEmpty()) {
        hmmerDomTablePfam = hmmerDomTablePfam.join('')
    } else {
        hmmerDomTablePfam = '-p ' + hmmerDomTablePfam.join('')
    }
    if(hmmerDomTableKegg.isEmpty()) {
        hmmerDomTableKegg = hmmerDomTableKegg.join('')
    } else {
        hmmerDomTableKegg = '-k ' + hmmerDomTableKegg.join('')
    }
    """
    hmmer_summary.py ${hmmerDomTablePfam} ${hmmerDomTableKegg} -l ${koList} -d ${diamond_result}
    """
}