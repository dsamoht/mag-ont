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
    tuple val(meta), path("hmmer_${type}.out")
    tuple val(meta), path("hmmer_dom-table_${type}.txt")
    
    script:
    """
    hmmsearch -E 0.001 -o hmmer_${type}.out --domtbl hmmer_dom-table_${type}.txt ${profile} ${genes}
    """
}