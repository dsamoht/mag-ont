process BWA {

    if (workflow.containerEngine == 'singularity') {
        container = params.bwa_singularity
    } else {
        container = params.bwa_docker
    }

    input:
    tuple val(meta), path(assembly)
    tuple val(sample_id), path(shortReads)

    output:
    tuple val(meta), path('fwd.sam'), emit: fwdSam
    tuple val(meta), path('rev.sam'), emit: revSam

    script:
    """
    bwa index ${assembly}
    bwa mem -a ${assembly} ${shortReads[0]} > fwd.sam
    bwa mem -a ${assembly} ${shortReads[1]} > rev.sam
    """
}