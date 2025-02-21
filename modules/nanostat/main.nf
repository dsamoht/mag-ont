process NANOSTAT {

    container workflow.containerEngine == 'singularity' ?
        params.nanostat_singularity : params.nanostat_docker

    publishDir "${params.outdir}/nanostat", mode: 'copy'

    input:
    path reads

    output:
    path('stats.tsv'), emit: tsv

    script:
    """
    NanoStat -o . -n stats.tsv --tsv --fastq ${reads}
    """
}
