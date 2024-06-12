process KRONA {

    if (workflow.containerEngine == 'singularity') {
        container = params.krona_singularity
    } else {
        container = params.krona_docker
    }

    publishDir "${params.outdir}/kraken", mode: 'copy'
    errorStrategy 'ignore'

    input:
    tuple val(meta), path(krakentoolsOutput)

    output:
    tuple val(meta), path('krona.html'), emit: kronaPlotHtml, optional: true

    script:
    """
    ktImportText ${krakentoolsOutput} -o krona.html
    """
}