process BWA {

    conda "bioconda::bwa=0.7.3a"
    if (workflow.containerEngine == 'singularity') {
        container = params.bwa_singularity
    } else {
        container = params.bwa_docker
    }

    input:
    tuple val(meta), path(assembly)
    tuple val(sample_id), path(shortReads)
    val sep

    output:
    tuple val(meta), path('fwd.sam'), emit: fwdSam, optional: true
    tuple val(meta), path('rev.sam'), emit: revSam, optional: true
    tuple val(meta), path('aln-pe.sam'), emit: alnPeSam, optional: true

    script:
    if (sep) {
        """
        bwa index ${assembly}
        bwa mem -a ${assembly} ${shortReads[0]} > fwd.sam
        bwa mem -a ${assembly} ${shortReads[1]} > rev.sam
        """
    } else {
        """
        bwa index ${assembly}
        bwa mem -a ${assembly} ${shortReads[0]} ${shortReads[1]} > aln-pe.sam
        """
    }
}