process FLYE {

    conda "bioconda::flye=2.9.2"
    if (workflow.containerEngine == 'singularity') {
        container = params.flye_singularity
    } else {
        container = params.flye_docker
    }

    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(meta), path(rawReads)

    output:
    tuple val(meta), path('*/assembly.fasta'), emit: flyeAssembly

    script:
    """
    flye --nano-raw ${rawReads} -o flye --meta --threads ${task.cpus}
    sed -i 's/>contig_/>${meta['name']}|contig_/' flye/assembly.fasta
    """
}