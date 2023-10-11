process SAMTOOLS {

    if (workflow.containerEngine == 'singularity') {
        container = params.samtools_singularity
    } else {
        container = params.samtools_docker
    }

    input:
    path samFile

    output:
    path 'map.sorted.bam', emit: bamFile

    script:
    """
    samtools view -bS ${samFile} | samtools sort -o map.sorted.bam -
    """
}