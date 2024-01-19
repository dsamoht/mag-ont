process PRODIGAL {

    if (workflow.containerEngine == 'singularity') {
        container = params.prodigal_singularity
    } else {
        container = params.prodigal_docker
    }

    publishDir "${params.outdir}/prodigal/", mode: 'copy'

    input:
    path assembly

    output:
    path 'genes.gff', emit: genesGff
    path 'genes.faa', emit: genesFaa
    path 'genes.fna', emit: genesFna

    script:
    """
    prodigal -i ${assembly} -f gff -o genes.gff -a genes.faa -d genes.fna -p meta
    """
}