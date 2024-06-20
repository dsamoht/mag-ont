process METAEUK_MODIFY_GFF {

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
    tuple val(meta), path("euk_genes_modif.gff"), emit: euk_gff_modif

    script:
    """
    modify_metaeuk_gff.py -f ${euk_fas} -g euk_genes_modif.gff
    """
}