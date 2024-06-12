process FEATURECOUNTS_SUMMARY {

    if (workflow.containerEngine == 'singularity') {
        container = params.pandas_singularity
    } else {
        container = params.pandas_docker
    }

    errorStrategy 'ignore'
    publishDir "${params.outdir}/featurecounts", mode: 'copy'

    input:
    tuple val(meta), path(counts)

    output:
    tuple val(meta), path("abundance_table.tsv"), emit: featurecountsSummary

    script:
    """
    make_abundance_table.py -p ${counts}
    """
}