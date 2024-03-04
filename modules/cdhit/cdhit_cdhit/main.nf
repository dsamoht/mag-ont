process CDHIT {

    if (workflow.containerEngine == 'singularity') {
        container = params.cdhit_singularity
    } else {
        container = params.cdhit_docker
    }

    publishDir "${params.outdir}/cdhit", mode: 'copy'

    input:
    path proteins

    output:
    path "proteins.cdhit.c95aL90.clstr", emit: clstr_file

    script:
    """
    cd-hit -i ${proteins} -o proteins.cdhit.c95aL90 -c 0.95 -aL 0.90 -n 5 -g 1 -M 0 -T ${task.cpus}
    """
}