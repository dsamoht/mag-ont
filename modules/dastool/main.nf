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

    output:
    path "contigs2bins.tsv", emit: contigs2bins, optional: true
    path "*/*bin*.fa", emit: dasBins, optional: true

    script:
    """
    Fasta_to_Contig2Bin.sh -e fa > contigs2bins.tsv
    cat ${bins} > contigs.fasta
    DAS_Tool -i contigs2bins.tsv -c contigs.fasta -o das-bin --write_bins --score_threshold 0.1
    """
}