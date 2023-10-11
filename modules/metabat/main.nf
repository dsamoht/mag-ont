process METABAT {

    if (workflow.containerEngine == 'singularity') {
        container = params.metabat_singularity
    } else {
        container = params.metabat_docker
    }

    publishDir "${params.outdir}/metabat", mode: 'copy'

    input:
    path medakaOutFile
    path sortedBamFile

    output:
    path "*metabat-bin*.fa", emit: metabatBins, optional: true
    path "depth.txt", emit: metabatDepth

    script:
    """
    jgi_summarize_bam_contig_depths --outputDepth depth.txt ${sortedBamFile}
    metabat2 -i ${medakaOutFile} -a depth.txt -o metabat-bin
    """
}