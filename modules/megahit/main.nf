process MEGAHIT {

    if (workflow.containerEngine == 'singularity') {
        container = params.megahit_singularity
    } else {
        container = params.megahit_docker
    }

    publishDir "${params.outdir}/megahit", mode: 'copy'

    errorStrategy 'ignore'

    input:
    tuple val(sample_id), path(shortReads)

    output:
    path "contigs.fna", emit: assembly

    script:
    """
    megahit -t ${task.cpus} -1 ${shortReads[0]} -2 ${shortReads[1]} -o megahit
    mv megahit/final.contigs.fa contigs.fna
    """
}