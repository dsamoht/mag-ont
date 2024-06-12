process MINIMAP {

    if (workflow.containerEngine == 'singularity') {
        container = params.minimap_singularity
    } else {
        container = params.minimap_docker
    }

    input:
    tuple val(meta), path(rawReads)
    tuple val(meta), path(medakaOutFile)

    output:
    tuple val(meta), path('map.sam'), emit: samFileOut

    script:
    """

    minimap2 -ax map-ont ${medakaOutFile} ${rawReads} > map.sam
    """
}