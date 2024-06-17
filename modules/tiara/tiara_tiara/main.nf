process TIARA {
   
    if (workflow.containerEngine == 'singularity') {
        container = params.tiara_singularity
    } else {
        container = params.tiara_docker
    }

    publishDir "${params.outdir}/tiara", mode: 'copy'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("classification.txt"), emit: classifications

    script:
    """
    tiara -i ${fasta} -o classification.txt --threads ${task.cpus}
    """
}