process MEDAKA {

    if (workflow.containerEngine == 'singularity') {
        container = params.medaka_singularity
    } else {
        container = params.medaka_docker
    }

    publishDir "${params.outdir}/medaka", mode: 'copy'

    input:
    path reads
    path assembly

    output:
    path('*/consensus.fasta'), emit: consensus

    script:
    """
    medaka_consensus -i ${reads} -d ${assembly} -o medaka -f -t ${task.cpus}
    """
}