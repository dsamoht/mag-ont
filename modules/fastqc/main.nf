process FASTQC {

    container workflow.containerEngine == 'singularity' ?
        params.fastqc_singularity : params.fastqc_docker

    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    path(reads)

    output:
    path("*.html"), emit: html
    path("*.zip"), emit: zip

    script:
    """
    fastqc --memory 6000 ${reads}
    """
}
