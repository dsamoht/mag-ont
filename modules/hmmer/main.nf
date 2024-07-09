process HMMER {

    conda "bioconda::hmmer=3.4"
    if (workflow.containerEngine == 'singularity') {
        container = params.hmmer_singularity
    } else {
        container = params.hmmer_docker
    }

    publishDir "${params.outdir}/hmmer", mode: 'copy'

    input:
    tuple val(meta), path(genes)
    tuple val(type), path(profile)

    output:
    tuple val(meta), path("hmmer_table_${type}.txt")
    //tuple val(meta), path("hmmer_${type}.out")
    
    script:
    """
    hmmsearch -E 0.001 -o /dev/null --tblout hmmer_table_${type}.txt --cpu ${task.cpus - 1} ${profile} ${genes}
    """
}