process PRODIGAL {

    conda "bioconda::prodigal=2.6.3"
    if (workflow.containerEngine == 'singularity') {
        container = params.prodigal_singularity
    } else {
        container = params.prodigal_docker
    }

    publishDir "${params.outdir}/prodigal/", mode: 'copy'

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path('genes.gff'), emit: genesGff
    tuple val(meta), path('genes.faa'), emit: genesFaa
    tuple val(meta), path('genes.fna'), emit: genesFna

    script:
    """
    prodigal -i ${assembly} -f gff -o genes.gff -a genes.faa -d genes.fna -p meta
    """
}