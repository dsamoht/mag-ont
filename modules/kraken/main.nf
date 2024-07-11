process KRAKEN {

    conda "bioconda::kraken2=2.1.3"
    if (workflow.containerEngine == 'singularity') {
        container = params.kraken_singularity
    } else {
        container = params.kraken_docker
    }

    publishDir "${params.outdir}/kraken", mode: 'copy'

    input:
    tuple val(meta), path(rawReads)
    path db
    val read_type

    output:
    tuple val(meta), path('tax.kraken'), emit: krakenOutputFile
    tuple val(meta), path('kraken.out'), emit: krakenStdOutput

    script:
    if(read_type == "paired") {
        """
        kraken2 --db ${db} --report tax.kraken --paired ${rawReads} --threads ${task.cpus} > kraken.out
        """
    } else if(read_type == "long") {
        """
        kraken2 --db ${db} --report tax.kraken ${rawReads} --threads ${task.cpus} > kraken.out
        """
    }
}