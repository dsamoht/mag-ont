process COVERM_GENOME {

    label "medium"

    tag "group_${meta}"

    container params.coverm_container

    publishDir "${params.outdir}/group_${meta}/binning/coverm", mode: "copy"

    input:
    tuple val(meta), path(dastool_bins, stageAs: "bins/*")
    tuple val(meta), path(bam_files)

    output:
    tuple val(meta), path("coverm_genome_stats.tsv"), emit: coverm_stats
    path("versions.yml"), emit: versions

    script:
    """
    coverm genome \
	--methods mean trimmed_mean covered_fraction \
	--genome-fasta-directory bins \
	--genome-fasta-extension fa \
	--bam-files ${bam_files} \
	--threads ${task.cpus} \
  	--output-file coverm_genome_stats.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coverm: \$(coverm --version | sed 's/coverm //')
    END_VERSIONS
    """
}
