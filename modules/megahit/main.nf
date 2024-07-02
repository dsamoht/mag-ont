process MEGAHIT {

    conda "bioconda::megahit=1.2.9"
    if (workflow.containerEngine == 'singularity') {
        container = params.megahit_singularity
    } else {
        container = params.megahit_docker
    }

    publishDir "${params.outdir}/megahit", mode: 'copy'

    errorStrategy 'ignore'

    input:
    tuple val(meta), path(shortReads)

    output:
    tuple val(meta), path("contigs.fna"), emit: assembly

    script:
    """
    megahit -t ${task.cpus} -1 ${shortReads[0]} -2 ${shortReads[1]} -o megahit
    mv megahit/final.contigs.fa contigs.fna
    sed -i 's/>/>${meta['name']}|/' contigs.fna
    """
}