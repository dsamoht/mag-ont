process PORECHOP_ABI {

    if (workflow.containerEngine == 'singularity') {
        container = params.porechop_abi_singularity
    } else {
        container = params.porechop_abi_docker
    }

    input:
    path reads

    output:
    path("*porechopped_reads.fastq.gz"), emit: porechopped_reads
    path("*porechop.log"), emit: log

    script:
    """
    porechop_abi --ab_initio -i ${reads} -o porechopped_reads.fastq.gz > porechop.log
    """
}
