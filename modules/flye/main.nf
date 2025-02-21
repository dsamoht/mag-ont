process FLYE {

    if (workflow.containerEngine == 'singularity') {
        container = params.flye_singularity
    } else {
        container = params.flye_docker
    }

    publishDir "${params.outdir}", mode: 'copy'

    input:
    path reads

    output:
    path('*/assembly.fasta'), emit: assembly

    script:
    """
    flye --nano-raw ${reads} -o flye --threads ${task.cpus}
    """
}