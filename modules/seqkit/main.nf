process SEQKIT {

    if (workflow.containerEngine == 'singularity') {
        container = params.seqkit_singularity
    } else {
        container = params.seqkit_docker
    }

    publishDir "${params.outdir}/seqkit/", mode: 'copy'

    input:
    path bins

    output:
    path('stats.tsv'), emit: seqkit_stats

    script:
    """
    seqkit stats -aTb ${bins} > stats.tsv
    """
}