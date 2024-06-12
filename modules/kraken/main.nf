process KRAKEN {

    if (workflow.containerEngine == 'singularity') {
        container = params.kraken_singularity
    } else {
        container = params.kraken_docker
    }

    publishDir "${params.outdir}/kraken", mode: 'copy'

    input:
    tuple val(meta), path(rawReads)
    path db

    output:
    tuple val(meta), path('tax.kraken'), emit: krakenOutputFile
    tuple val(meta), path('kraken.out'), emit: krakenStdOutput

    script:
    """
    kraken2 --db ${db} --report tax.kraken ${rawReads} --threads ${task.cpus} > kraken.out
    """
}