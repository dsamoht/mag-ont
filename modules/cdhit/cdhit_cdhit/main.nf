process CDHIT_CDHIT {

    if (workflow.containerEngine == 'singularity') {
        container = params.cdhit_singularity
    } else {
        container = params.cdhit_docker
    }

    publishDir "${params.outdir}/cdhit", mode: 'copy'

    input:
    tuple val(meta), path(proteins)
    path database
    val database_name

    output:
    tuple val(meta), path("${database_name}.cdhit.c70aL50.clstr"), emit: clstr_file

    script:
    """
    sed -i "s/^>/>DATABASE|/g" ${database}
    sed -i "s/^>/>SAMPLE|/g" ${proteins}
    cd-hit-2d -i ${database} -i2 ${proteins} -o ${database_name}.cdhit.c70aL50 -g 1 -c 0.7 -n 5 -M 0 -d 0 -T ${task.cpus}
    """
}