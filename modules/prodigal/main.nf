process PRODIGAL {

    if (workflow.containerEngine == 'singularity') {
        container = params.prodigal_singularity
    } else {
        container = params.prodigal_docker
    }

    publishDir "${params.outdir}/prodigal/", mode: 'copy'

    input:
    path medakaOutFile

    output:
    path 'coords.gbk', emit: coordsOut
    path 'genes.faa', emit: genesOut

    script:
    """
    prodigal -i ${medakaOutFile} -o coords.gbk -a genes.faa -p meta
    """
}