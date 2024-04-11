process DIAMOND_MAKEDB {

    if (workflow.containerEngine == 'singularity') {
        container = params.diamond_singularity
    } else {
        container = params.diamond_docker
    }

    //errorStrategy 'ignore'
    publishDir "${params.database_path}/", mode: 'copy'

    input:
    path fasta
    val name

    output:
    path "*${name}.dmnd", emit: diamond_db

    script:
    """
    diamond makedb --in ${fasta} -p ${task.cpus} --db ${name}.dmnd
    """
}
