process SEQKIT {

    if (workflow.containerEngine == 'singularity') {
        container = params.seqkit_singularity
    } else {
        container = params.seqkit_docker
    }

    errorStrategy 'ignore'

    publishDir "${params.outdir}/seqkit/", mode: 'copy'

    input:
    tuple val(meta), path(bins)

    output:
    tuple val(meta), (path 'stats.tsv'), emit: seqkitStats

    script:
    """
    seqkit stats -aTb ${bins} > stats.tsv
    """
}