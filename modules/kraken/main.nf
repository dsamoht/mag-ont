process KRAKEN {

    if (workflow.containerEngine == 'singularity') {
        container = params.kraken_singularity
    } else {
        container = params.kraken_docker
    }

    publishDir "${params.outdir}/kraken", mode: 'copy'

    input:
    path rawReads
    path db

    output:
    path 'tax.kraken', emit: krakenOutputFile
    path 'kraken.out', emit: krakenStdOutput

    script:
    """
    kraken2 --db ${db} --report tax.kraken ${rawReads} --threads ${task.cpus} > kraken.out
    """
}