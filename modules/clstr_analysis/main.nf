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
    path gtdbtk
    
    output:
    tuple val(meta), path("clusters_info_polars.pkl"), emit: clstrPolars
    tuple val(meta), path("**_annotation.tsv"), emit: clstrAnnotation
    tuple val(meta), path("**_abundance.tsv"), emit: clstrAbundance

    script:
    def gtdbtk_res = gtdbtk.name != 'NO_FILE' ? "-t $gtdbtk" : ''
    """
    clstr_utilities.py -c ${clusters} -f ${genes} -n ${annotation} -a ${abundance} ${gtdbtk_res}
    """

}