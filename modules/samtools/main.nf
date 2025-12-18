process SAMTOOLS {

    if (workflow.containerEngine == 'singularity') {
        container = params.samtools_singularity
    } else {
        container = params.samtools_docker
    }

    publishDir "${params.outdir}/samtools", mode: 'copy'

    input:
    path sam_file

    output:
    path('sorted.bam'), emit: bam_file

    script:
    """
    samtools view -bS ${sam_file} | samtools sort -o sorted.bam -
    """
}
