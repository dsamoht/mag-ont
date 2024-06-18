process CDHIT {

    if (workflow.containerEngine == 'singularity') {
        container = params.cdhit_singularity
    } else {
        container = params.cdhit_docker
    }

    publishDir "${params.outdir}/cdhit", mode: 'copy'

    input:
    tuple val(meta), path(proteins)

    output:
    tuple val(meta), path("cdhit_c95aS90.clstr"), emit: clstr_file

    script:
    """
    cd-hit -i ${proteins} -o cdhit_c95aS90 -c 0.95 -G 0 -aS 0.9 -g 1 -d 0 -s 0.8 -T ${task.cpus}
    """
}