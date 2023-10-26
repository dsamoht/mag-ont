process METABAT {

    if (workflow.containerEngine == 'singularity') {
        container = params.metabat_singularity
    } else {
        container = params.metabat_docker
    }
    errorStrategy 'ignore'

    publishDir "${params.outdir}/metabat", mode: 'copy'

    input:
    path medakaOutFile
    path("*map.sorted.bam")

    output:
    path "*metabat-bin*.fa", emit: metabatBins, optional: true
    path "depth.txt", emit: metabatDepth

    script:
    """
    jgi_summarize_bam_contig_depths --outputDepth depth.txt *map.sorted.bam
    metabat2 -i ${medakaOutFile} -a depth.txt -o metabat-bin
    """
}