process CONCATENATE_FILES {

    publishDir "${params.outdir}/concat_files", mode: 'copy'

    input:
    tuple val(meta), path(input_dir)

    output:
    tuple val(meta), path('genes_all.faa'), emit: genesConcat
    tuple val(meta), path('genes_annot_all.tsv'), emit: genesAnnotConcat
    tuple val(meta), path('genes_abund_all.tsv'), emit: genesAbundConcat
    path 'gtdbtk_taxo_all.tsv', emit: gtdbtkConcat, optional: true

    script:
    def genes_files = input_dir.collect { i -> i + '/prodigal/genes.faa'}.join(' ')
    def annot_files = input_dir.collect { i -> i + '/hmmer/genes_annot_summary.tsv'}.join(' ')
    def abund_files = input_dir.collect { i -> i + '/featurecounts/genes_abundance.tsv'}.join(' ')
    def gtdbtk_files = input_dir.collect { i -> i + '/gtdbtk/contig_taxo_annot.tsv'}.join(' ')

    """
    gtdbtk_res=""
    gtdbtk_exist=false

    gtdbtk_array=(${gtdbtk_files})
    for f in \${gtdbtk_array[@]}
    do
    if [[ -f \$f ]]; then
    gtdbtk_res="\${gtdbtk_res} \${f}"
    gtdbtk_exist=true
    fi
    done
    if [ "\$gtdbtk_exist" = true ] ; then
    awk 'FNR==1 && NR!=1{next;}{print}' \$gtdbtk_res > gtdbtk_taxo_all.tsv
    fi
    cat ${genes_files} > genes_all.faa
    awk 'FNR==1 && NR!=1{next;}{print}' ${annot_files} > genes_annot_all.tsv
    awk 'FNR==1 && NR!=1{next;}{print}' ${abund_files} > genes_abund_all.tsv
    """
}