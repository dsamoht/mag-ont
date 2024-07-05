process CONCATENATE_FILES {

    publishDir "${params.outdir}/concat_files", mode: 'copy'

    input:
    tuple val(meta), path(input_dir)

    output:
    tuple val(meta), path('genes_all.faa'), emit: genesConcat
    tuple val(meta), path('genes_annot_all.tsv'), emit: genesAnnotConcat
    tuple val(meta), path('genes_abund_all.tsv'), emit: genesAbundConcat
    path 'bin_annotation_all.tsv', emit: binAnnotConcat, optional: true
    path 'contigs2bins_all.tsv', emit: c2bConcat, optional: true

    script:
    def genes_files = input_dir.collect { i -> i + '/prodigal/genes.faa'}.join(' ')
    def annot_files = input_dir.collect { i -> i + '/hmmer/genes_annot_summary.tsv'}.join(' ')
    def abund_files = input_dir.collect { i -> i + '/featurecounts/genes_abundance.tsv'}.join(' ')
    def bin_annotation_dir = input_dir.collect { i -> i + '/bin_annotation'}.join(' ')

    """
    bin_annotation_res=""
    c2b_res=""
    bin_exist=false

    bin_array=(${bin_annotation_dir})
    for d in \${bin_array[@]}
    do
    if [[ -d \$d ]]; then
    bin_annotation_res="\${bin_annotation_res} \${d}/bin_annotation.tsv "
    c2b_res="\${c2b_res} \${d}/contigs2bins.tsv "
    bin_exist=true
    fi
    done
    if [[ "\$bin_exist" = true ]] ; then
    awk 'FNR==1 && NR!=1{next;}{print}' \$bin_annotation_res > bin_annotation_all.tsv
    awk 'FNR==1 && NR!=1{next;}{print}' \$c2b_res > contigs2bins_all.tsv
    fi
    cat ${genes_files} > genes_all.faa
    awk 'FNR==1 && NR!=1{next;}{print}' ${annot_files} > genes_annot_all.tsv
    awk 'FNR==1 && NR!=1{next;}{print}' ${abund_files} > genes_abund_all.tsv
    """
}