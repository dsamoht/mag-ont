| process FEATURECOUNTS {

    if (workflow.containerEngine == 'singularity') {
        container = params.subread_singularity
    } else {
        container = params.subread_docker
    }

    errorStrategy 'ignore'
    publishDir "${params.outdir}/featurecounts", mode: 'copy'

    input:
    path genesGff
    path sorted_bam

    output:
    path "*featureCounts.txt", emit: counts
    path "*featureCounts.txt.summary", emit: summary

    script:
    """
    featureCounts -L -O --largestOverlap -t CDS -g ID -s 0 -a ${genesGff} -o featureCounts.txt ${sorted_bam}
    """
}

