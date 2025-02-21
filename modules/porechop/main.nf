process PORECHOP {

    if (workflow.containerEngine == 'singularity') {
        container = params.porechop_singularity
    } else {
        container = params.porechop_docker
    }

    input:
    path reads

    output:
    path("*porechopped_reads.fastq.gz"), emit: porechopped_reads
    path("*porechop.log"), emit: log

    script:
    """
    porechop -i ${reads} -o porechopped_reads.fastq.gz > porechop.log
    """
}
