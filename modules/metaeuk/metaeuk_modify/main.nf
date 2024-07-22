process METAEUK_MODIFY {

    conda "conda-forge::python=3.9"
    if (workflow.containerEngine == 'singularity') {
        container = params.python_singularity
    } else {
        container = params.python_docker
    }

    publishDir "${params.outdir}/metaeuk", mode: 'copy'
    
    input:
    tuple val(meta), path(euk_fas)

    output:
    tuple val(meta), path("euk_genes_modif.fas"), emit: euk_fas_modif

    script:
    """
    modify_metaeuk_fasta.py -f ${euk_fas} -o euk_genes_modif.fas
    """
}