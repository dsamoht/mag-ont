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
    path krakenOutputFile
    path db

    output:
    path 'tax.bracken', emit: brackenOutputFile, optional: true
    path 'tax_bracken_species.kraken', emit: brackenOutputForKrona, optional: true
    path 'krona.html', emit: kronaPlotHtml, optional: true

    script:
    """
    est_abundance.py -i ${krakenOutputFile} -k ${db}/database200mers.kmer_distrib -l S -t 10 -o tax.bracken
    """
}