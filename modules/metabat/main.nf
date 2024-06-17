process METABAT {

    if (workflow.containerEngine == 'singularity') {
        container = params.metabat_singularity
    } else {
        container = params.metabat_docker
    }
    
    //errorStrategy 'ignore'

    publishDir "${params.outdir}/metabat", mode: 'copy'

    input:
    tuple val(meta), path(assembly)
    tuple val(meta), path(sorted_bam)

    output:
    tuple val(meta), path("*metabat-bin*.fa"), emit: metabatBins, optional: true
    tuple val(meta), path("depth.txt"), emit: metabatDepth

    script:
    """
    jgi_summarize_bam_contig_depths --outputDepth depth.txt ${sorted_bam}
    metabat2 -i ${assembly} -a depth.txt -o metabat-bin
    """
}