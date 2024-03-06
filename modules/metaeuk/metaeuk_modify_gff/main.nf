process METAEUK_MODIFY_GFF {

    if (workflow.containerEngine == 'singularity') {
        container = params.python_singularity
    } else {
        container = params.python_docker
    }

    publishDir "${params.outdir}/metaeuk", mode: 'copy'
    
    input:
    path euk_fas

    output:
    path "euk_genes_modif.gff", emit: euk_gff_modif

    script:
    """
    modify_metaeuk_gff.py -f ${euk_fas} -g euk_genes_modif.gff
    """
}