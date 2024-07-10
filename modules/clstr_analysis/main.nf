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
    tuple val(meta), path("clusters_info_polars.pkl"), emit: clstrPolars
    tuple val(meta), path("abundance_clusters_polars.pkl"), emit: abundPolars
    tuple val(meta), path("annotation_clusters_polars.pkl"), emit: annotPolars
    tuple val(meta), path("bin_annotation_all.pkl"), emit: binPolars, optional: true
    tuple val(meta), path("contigs2bins_all.pkl"), emit: c2bPolars, optional: true
    //tuple val(meta), path("**_annotation.tsv"), emit: clstrAnnotation
    //tuple val(meta), path("**_abundance.tsv"), emit: clstrAbundance

    script:
    """
    if ! [ -f NO_FILE ]
    then
    clstr_utilities.py -c ${clusters} -f ${genes} -n ${annotation} -a ${abundance} -b ${bin_annot_concat} -t ${c2b_concat}
    else
    clstr_utilities.py -c ${clusters} -f ${genes} -n ${annotation} -a ${abundance}
    fi
    """

}