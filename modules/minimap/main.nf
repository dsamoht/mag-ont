process MINIMAP {

    if (workflow.containerEngine == 'singularity') {
        container = params.minimap_singularity
    } else {
        container = params.minimap_docker
    }

    input:
    path reads
    path assembly

    output:
    path('map.sam'), emit: sam

    script:
    """
    minimap2 -ax map-ont ${assembly} ${reads} > map.sam
    """
}