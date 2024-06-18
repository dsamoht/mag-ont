process CONCATENATE_FILES {

    publishDir "${params.outdir}/concat_files", mode: 'copy'

    input:
    path genes_files
    path annot_files
    path abund_files

    output:
    path 'genes_all.faa', emit: genesConcat
    path 'genes_annot_all.tsv', emit: genesAnnotConcat
    path 'genes_abund_all.tsv', emit: genesAbundConcat

    script:
    """
    cat ${genes_files} > genes_all.faa
    awk 'FNR==1 && NR!=1{next;}{print}' ${annot_files} > genes_annot_all.tsv
    awk 'FNR==1 && NR!=1{next;}{print}' ${abund_files} > genes_abund_all.tsv
    """
}