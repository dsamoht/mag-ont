process METABAT {

    if (workflow.containerEngine == 'singularity') {
        container = params.metabat_singularity
    } else {
        container = params.metabat_docker
    }
    
    publishDir "${params.outdir}/metabat", mode: 'copy'

    input:
    path assembly
    path sorted_bam

    output:
    path("*metabat-bin*.fa"), emit: metabat_bins, optional: true
    path("depth.txt"), emit: metabat_depth

    script:
    """
    jgi_summarize_bam_contig_depths --outputDepth depth.txt ${sorted_bam}
    metabat2 -i ${assembly} -a depth.txt -o metabat-bin
    """
}