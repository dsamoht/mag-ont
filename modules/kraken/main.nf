process KRAKEN {

    if (workflow.containerEngine == 'singularity') {
        container = params.kraken_singularity
    } else {
        container = params.kraken_docker
    }

    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: 'tax.kraken'

    input:
    path rawReads
    path db

    output:
    path 'tax.kraken', emit: krakenOutputFile

    script:
    """
    kraken2 --db ${db} --report tax.kraken ${rawReads} --threads ${task.cpus}
    """
}