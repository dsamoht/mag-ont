process FEATURECOUNTS_SUMMARY {

    if (workflow.containerEngine == 'singularity') {
        container = params.pandas_singularity
    } else {
        container = params.pandas_docker
    }

    errorStrategy 'ignore'
    publishDir "${params.outdir}/featurecounts", mode: 'copy'

    input:
    path counts

    output:
    path "abundance_table.tsv", emit: featurecountsSummary

    script:
    """
    make_abundance_table.py -p ${counts}
    """
}