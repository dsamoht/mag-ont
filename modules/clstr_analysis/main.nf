process CLSTR_ANALYSIS {

    conda "conda-forge::polars=0.18.15"
    if (workflow.containerEngine == 'singularity') {
        container = params.polars_singularity
    } else {
        container = params.polars_docker
    }

    publishDir "${params.outdir}/cluster_analysis", mode: 'copy'

    input:
    tuple val(meta), path(clusters)
    tuple val(meta), path(genes)
    tuple val(meta), path(annotation)
    tuple val(meta), path(abundance)
    path bin_annot_concat
    path c2b_concat
    
    output:
    tuple val(meta), path("clusters_info.tsv"), emit: clstrInfo
    tuple val(meta), path("clusters_annotation.tsv"), emit: clstrAnnotation
    tuple val(meta), path("clusters_abundance.tsv"), emit: clstrAbundance
    tuple val(meta), path("bin_annotation_all.tsv"), emit: binTsv, optional: true
    tuple val(meta), path("contigs2bins_all.tsv"), emit: c2bTsv, optional: true

    script:
    """
    clstr_utilities.py -c ${clusters} -f ${genes} -n ${annotation} -a ${abundance}
    """
}