process COVERM {

    container "/project/roshab/software/singularity_images/coverm_0.7.0--hcb7b614_4.sif"

    publishDir "${params.output}/coverm", mode: 'copy'

    input:
    path(dasBins, stageAs: "input_bins/*")
    path bam_files

    output:
    path("coverm_stats.tsv"), emit: coverm_stats

    script:
    """
    coverm genome --methods relative_abundance trimmed_mean covered_fraction --genome-fasta-directory input_bins --genome-fasta-extension fa --bam-files ${bam_files} --exclude-supplementary --threads ${task.cpus} --output-file coverm_stats.tsv
    """
}
