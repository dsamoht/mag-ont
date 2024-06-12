process BRACKEN {

    if (workflow.containerEngine == 'singularity') {
        container = params.bracken_singularity
    } else {
        container = params.bracken_docker
    }

    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: 'tax.bracken'
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: 'krona.html'
    errorStrategy 'ignore'

    input:
    tuple val(meta), path(krakenOutputFile)
    path db

    output:
    tuple val(meta), path('tax.bracken'), emit: brackenOutputFile, optional: true
    tuple val(meta), path('tax_bracken_species.kraken'), emit: brackenOutputForKrona, optional: true
    tuple val(meta), path('krona.html'), emit: kronaPlotHtml, optional: true

    script:
    """
    est_abundance.py -i ${krakenOutputFile} -k ${db}/database200mers.kmer_distrib -l S -t 10 -o tax.bracken
    """
}