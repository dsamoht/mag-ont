process FLYE {

    container = "quay.io/biocontainers/flye:2.9.6--py310h275bdba_0"

    publishDir "${params.outdir}", mode: 'copy'

    input:
    path reads

    output:
    path('*/assembly.fasta'), emit: assembly

    script:
    """
    flye \
        --nano-hq ${reads} \
        -o flye \
        --threads ${task.cpus} \
        --meta
    """
}
