process CHOPPER {

    if (workflow.containerEngine == 'singularity') {
        container = params.chopper_singularity
    } else {
        container = params.chopper_docker
    }
    
    //errorStrategy 'ignore'

    publishDir "${params.outdir}/chopper", mode: 'copy'

    input:
    tuple val(meta), path(raw_reads)

    output:
    tuple val(meta), path("qc_reads.fastq.gz"), emit: qc_reads

    script:
    """
    zcat ${raw_reads} | chopper --headcrop 40 --threads ${task.cpus} | chopper -l 500 --threads ${task.cpus} | chopper -q 10 --threads ${task.cpus} | gzip > qc_reads.fastq.gz
    """
}