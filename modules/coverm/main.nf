process COVERM {

    tag "group_${meta}"

    container params.coverm_container

    input:
    tuple val(meta), path(dastool_bins, stageAs: "bins/*")
    tuple val(meta), path(bam_files)

    output:
    tuple val(meta), path("coverm_stats.tsv"), emit: coverm_stats

    script:
    """
    coverm genome \
	--methods relative_abundance trimmed_mean covered_fraction \
	--genome-fasta-directory bins \
	--genome-fasta-extension fa \
	--bam-files ${bam_files} \
	--exclude-supplementary \
	--threads ${task.cpus} \
  	--output-file coverm_stats.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coverm: \$(coverm --version | sed 's/coverm //')
    END_VERSIONS
    """
}
