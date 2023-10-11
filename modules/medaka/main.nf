process MEDAKA {

    if (workflow.containerEngine == 'singularity') {
        container = params.medaka_singularity
    } else {
        container = params.medaka_docker
    }

    publishDir "${params.outdir}", mode: 'copy'

    input:
    path rawReads
    path flyeAssembly

    output:
    path '*/consensus.fasta', emit: medakaOutFile

    script:
    """
    medaka_consensus -i ${rawReads} -d ${flyeAssembly} -o medaka -f -t ${task.cpus}
    """
}