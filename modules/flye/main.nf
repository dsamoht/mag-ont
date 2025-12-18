process FLYE {

    if (workflow.containerEngine == 'singularity') {
        container = params.flye_singularity
    } else {
        container = params.flye_docker
    }

    publishDir "${params.outdir}", mode: 'copy'

    input:
    path rawReads

    output:
    path '*/assembly.fasta', emit: flyeAssembly

    script:
    """
    flye --nano-raw ${rawReads} -o flye --meta --threads ${task.cpus}
    """
}