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
    def args = params.meta ? '--meta' : ''
    """
    flye --nano-raw ${reads} -o flye --threads ${task.cpus} ${args}
    """
}
