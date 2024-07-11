process BOWTIE {

    conda "bioconda::bowtie2=2.5.3"
    if (workflow.containerEngine == 'singularity') {
        container = params.bowtie_singularity
    } else {
        container = params.bowtie_docker
    }

    input:
    tuple val(meta), path(assembly)
    tuple val(meta), path(shortReads)

    output:
    tuple val(meta), path('short_reads.sam'), emit: short_reads_sam

    script:
    """
    bowtie2-build ${assembly} assembly.bt2
    bowtie2 -x assembly.bt2 -1 ${shortReads[0]} -2 ${shortReads[1]} --no-unal -S short_reads.sam
    """
}