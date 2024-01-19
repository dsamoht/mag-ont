process SAMTOOLS {

    if (workflow.containerEngine == 'singularity') {
        container = params.samtools_singularity
    } else {
        container = params.samtools_docker
    }

    publishDir "${params.outdir}/samtools", mode: 'copy'

    input:
    path samFile
    val origin

    output:
    path '*.map.sorted.bam', emit: bamFile

    script:
    """
    samtools view -bS ${samFile} | samtools sort -o ${origin}.map.sorted.bam -
    """
}