process DIAMOND_MAKEDB {

    conda "bioconda::diamond=2.1.9"
    if (workflow.containerEngine == 'singularity') {
        container = params.diamond_singularity
    } else {
        container = params.diamond_docker
    }

    //errorStrategy 'ignore'
    publishDir "${params.database_path}/", mode: 'copy'

    input:
    tuple val(name), path(fasta)

    output:
    tuple val(name), path("*${name}.dmnd"), emit: diamond_db

    script:
    """
    diamond makedb --in ${fasta} -p ${task.cpus} --db ${name}.dmnd
    """
}
