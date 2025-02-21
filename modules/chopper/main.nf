process CHOPPER {

    if (workflow.containerEngine == 'singularity') {
        container = params.chopper_singularity
    } else {
        container = params.chopper_docker
    }

    publishDir "${params.outdir}/chopper", mode: 'copy'

    input:
    path(reads)

    output:
    path("qc_reads.fastq.gz"), emit: qc_reads

    script:
    """
    zcat ${reads} | chopper -l 500 --threads ${task.cpus} | chopper -q 10 --threads ${task.cpus} | gzip > qc_reads.fastq.gz
    """
}