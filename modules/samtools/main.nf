process SAMTOOLS {

    if (workflow.containerEngine == 'singularity') {
        container = params.samtools_singularity
    } else {
        container = params.samtools_docker
    }

    publishDir "${params.outdir}/samtools", mode: 'copy'

    input:
    tuple val(meta), path(samFile)
    val origin

    output:
    tuple val(meta), path('*.map.sorted.bam'), emit: bamFile

    script:
    """
    samtools view -bS ${samFile} | samtools sort -o ${origin}.map.sorted.bam -
    """
}