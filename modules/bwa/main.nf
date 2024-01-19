process BWA {

    if (workflow.containerEngine == 'singularity') {
        container = params.bwa_singularity
    } else {
        container = params.bwa_docker
    }

    input:
    path assembly
    tuple val(sample_id), path(shortReads)

    output:
    path 'fwd.sam', emit: fwdSam
    path 'rev.sam', emit: revSam

    script:
    """
    bwa index ${assembly}
    bwa mem -a ${assembly} ${shortReads[0]} > fwd.sam
    bwa mem -a ${assembly} ${shortReads[1]} > rev.sam
    """
}