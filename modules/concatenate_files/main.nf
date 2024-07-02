process CONCATENATE_FILES {

    publishDir "${params.outdir}/concat_files", mode: 'copy'

    input:
    tuple val(meta), path(input_dir)

    output:
    tuple val(meta), path('genes_all.faa'), emit: genesConcat
    tuple val(meta), path('genes_annot_all.tsv'), emit: genesAnnotConcat
    tuple val(meta), path('genes_abund_all.tsv'), emit: genesAbundConcat

    script:
    def genes_files = input_dir.collect { i -> i + '/prodigal/genes.faa'}.join(' ')
    def annot_files = input_dir.collect { i -> i + '/hmmer/genes_annot_summary.tsv'}.join(' ')
    def abund_files = input_dir.collect { i -> i + '/featurecounts/genes_abundance.tsv'}.join(' ')
    """
    cat ${genes_files} > genes_all.faa
    awk 'FNR==1 && NR!=1{next;}{print}' ${annot_files} > genes_annot_all.tsv
    awk 'FNR==1 && NR!=1{next;}{print}' ${abund_files} > genes_abund_all.tsv
    """
}