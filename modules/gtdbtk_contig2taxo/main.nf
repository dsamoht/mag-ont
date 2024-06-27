process GTDBTK_C2T {

    conda "conda-forge::pandas=2.2.1"
    if (workflow.containerEngine == 'singularity') {
        container = params.pandas_singularity
    } else {
        container = params.pandas_docker
    }

    publishDir "${params.outdir}/gtdbtk", mode: 'copy'

    input:
    tuple val(meta), path(contigs2bins)
    tuple val(meta), path(gtdbtk)

    output:
    tuple val(meta), path('contig_taxo_annot.tsv'), emit: contigTaxo

    script:
    """
    cat ${contigs2bins} > contigs2bins.tsv
    awk 'FNR==1 && NR!=1{next;}{print}' ${gtdbtk} > gtdbtk.summary.tsv
    annotate_contig_by_bin.py -c contigs2bins.tsv -g gtdbtk.summary.tsv
    """
}