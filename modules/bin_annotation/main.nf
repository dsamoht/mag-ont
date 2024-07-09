process BIN_ANNOTATION {

    conda "conda-forge::pandas=2.2.1"
    if (workflow.containerEngine == 'singularity') {
        container = params.pandas_singularity
    } else {
        container = params.pandas_docker
    }

    publishDir "${params.outdir}/bin_annotation", mode: 'copy'

    input:
    tuple val(meta), path(contigs2bins)
    tuple val(meta1), path(gtdbtk)
    tuple val(meta), path(seqkitStats)
    tuple val(meta), path(checkmStats)

    output:
    tuple val(meta), path('bin_annotation.tsv'), emit: binAnnotation
    tuple val(meta), path('contigs2bins.tsv'), emit: contigs2Bins

    script:
    """
    cat ${contigs2bins} > contigs2bins.tsv
    awk 'FNR==1 && NR!=1{next;}{print}' ${gtdbtk} > gtdbtk.summary.tsv
    annotate_bin.py -b contigs2bins.tsv -g gtdbtk.summary.tsv -s ${seqkitStats} -c ${checkmStats}
    sed -i 's/metabat/${meta['name']}|metabat/' bin_annotation.tsv
    sed -i 's/maxbin/${meta['name']}|maxbin/' bin_annotation.tsv
    sed -i 's/metabat/${meta['name']}|metabat/' contigs2bins.tsv
    sed -i 's/maxbin/${meta['name']}|maxbin/' contigs2bins.tsv
    """
}