process CONCATENATE_FILES {

    publishDir "${params.outdir}/concat_files", mode: 'copy'

    input:
    tuple val(meta), path(genes_files)
    tuple val(meta), path(annot_files)
    tuple val(meta), path(abund_files)

    output:
    tuple val(meta), path('genes_all.faa'), emit: genesConcat
    tuple val(meta), path('genes_annot_all.tsv'), emit: genesAnnotConcat
    tuple val(meta), path('genes_abund_all.tsv'), emit: genesAbundConcat

    script:
    """
    cat ${genes_files} > genes_all.faa
    awk 'FNR==1 && NR!=1{next;}{print}' ${annot_files} > genes_annot_all.tsv
    awk 'FNR==1 && NR!=1{next;}{print}' ${abund_files} > genes_abund_all.tsv
    """
}