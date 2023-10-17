process DASTOOL {

    if (workflow.containerEngine == 'singularity') {
        container = params.dastool_singularity
    } else {
        container = params.dastool_docker
    }

    errorStrategy 'ignore'

    publishDir "${params.outdir}/dastool", mode: 'copy', saveAs: { filename -> new File(filename).getName() }

    input:
    path bins
    path contig2bin

    output:
    path "das-bin*/*bin*.fa", emit: dasBins, optional: true

    script:
    def contig2binList = contig2bin.join(",")
    def label = contig2bin instanceof List ? "metabat,maxbin" : contig2bin.toString() - "_contigs2bins.tsv"
    """
    cat ${bins} > contigs.fasta
    DAS_Tool -i ${contig2binList} -l ${label} -c contigs.fasta -o das-bin --write_bins --score_threshold 0.1
    """
}