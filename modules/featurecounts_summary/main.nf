process FEATURECOUNTS_SUMMARY {

    conda "conda-forge::pandas=2.2.1"
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
    tuple val(meta), path("genes_abundance.tsv"), emit: featurecountsSummary

    script:
    """
    genes_abundance_table.py -p ${counts}
    """
}