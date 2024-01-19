process BEDTOOLS {

    if (workflow.containerEngine == 'singularity') {
        container = params.bedtools_singularity
    } else {
        container = params.bedtools_docker
    }

    publishDir "${params.outdir}/bedtools", mode: 'copy'

    input:
    path prodigalGff
    path sorted_bam

    output:
    path 'genes.cov', emit: genesCoverage

    script:
    """
    bedtools coverage -a ${prodigalGff} -b ${sorted_bam} > genes.cov
    """
}