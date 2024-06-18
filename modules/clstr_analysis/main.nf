process CLSTR_ANALYSIS {

    if (workflow.containerEngine == 'singularity') {
        container = params.python_singularity
    } else {
        container = params.python_docker
    }

    publishDir "${params.outdir}/cluster_analysis", mode: 'copy'

    input:
    tuple val(meta), path(clusters)
    tuple val(meta), path(genes)
    tuple val(meta), path(annotation)
    tuple val(meta), path(abundance)
    
    output:
    tuple val(meta), path("*_annotations.tsv"), emit: clstrAnnotation
    tuple val(meta), path("*_abundance.tsv"), emit: clstrAbundance

    script:
    """
    python clstr_utilities.py -c ${clusters} -f ${genes} -n ${annotation} -a ${abundance}
    """

}