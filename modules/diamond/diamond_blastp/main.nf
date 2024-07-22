process DIAMOND_BLASTP {

    conda "bioconda::diamond=2.1.9"
    if (workflow.containerEngine == 'singularity') {
        container = params.diamond_singularity
    } else {
        container = params.diamond_docker
    }

    //errorStrategy 'ignore'
    publishDir "${params.outdir}/diamond", mode: 'copy'

    input:
    tuple val(meta), path(proteins)
    tuple val(diamond_db_name), path(diamond_db)

    output:
    tuple val(meta), path("${diamond_db_name}.matches.tsv"), emit: diamond_result

    script:
    """
    diamond blastp -d ${diamond_db} -q ${proteins} -o ${diamond_db_name}.matches.tsv -k 1 --very-sensitive
    """
}
