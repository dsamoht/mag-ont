process NORMALIZE_COVERM_GENOME {

    label "small"

    tag "group_${meta}"

    container params.python_container

    publishDir "${params.outdir}/group_${meta}/binning/coverm", mode: 'copy'

    input:
    tuple val(meta), path(coverm_genome_stats)
    tuple val(meta), path(bam_files)

    output:
    tuple val(meta), path("coverm_genome_stats_norm.tsv"), emit: coverm_genome_norm

    script:
    """
    normalize_coverm_genome.py \
        --input ${coverm_genome_stats} \
        --bams ${bam_files.join(' ')} \
        --output coverm_genome_stats_norm.tsv
    """
}
