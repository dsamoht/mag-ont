process MINIMAP {

    if (workflow.containerEngine == 'singularity') {
        container = params.minimap_singularity
    } else {
        container = params.minimap_docker
    }

    input:
    path rawReads
    path medakaOutFile

    output:
    path 'map.sam', emit: samFileOut

    script:
    """

    minimap2 -ax map-ont ${medakaOutFile} ${rawReads} > map.sam
    """
}