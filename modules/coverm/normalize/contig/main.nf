process NORMALIZE_COVERM_CONTIG {

    label "small"

    tag "group_${meta}"

    container params.python_container

    publishDir "${params.outdir}/group_${meta}/mapping/genes", mode: 'copy'

    input:
    tuple val(meta), path(coverm_contig_stats)
    tuple val(meta), path(gff_file)
    tuple val(meta), path(bam_files)

    output:
    tuple val(meta), path("gene_abund_norm.tsv"), emit: gene_abund_norm

    script:
    """
    normalize_coverm_contig.py \
        --input ${coverm_contig_stats} \
        --gff ${gff_file} \
        --bams ${bam_files.join(' ')} \
        --output gene_abund_norm.tsv
    """
}
