process HMMER_SUMMARY {

    if (workflow.containerEngine == 'singularity') {
        container = params.pandas_singularity
    } else {
        container = params.pandas_docker
    }

    publishDir "${params.outdir}/hmmer", mode: 'copy'

    input:
    path hmmerDomTablePfam
    path hmmerDomTableKegg
    path koList

    output:
    path 'contig_annotation.tsv', emit: hmmerSummary


    script:
    """
    hmmer_summary.py -p ${hmmerDomTablePfam} -k ${hmmerDomTableKegg} -l ${koList}
    """
}