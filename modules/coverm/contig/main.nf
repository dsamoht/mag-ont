process COVERM_CONTIG {

    label "medium"

    tag "group_${meta}"

    container params.coverm_container

    publishDir "${params.outdir}/group_${meta}/mapping/coverm", mode: "copy"

    input:
    tuple val(meta), path(bam_files)

    output:
    tuple val(meta), path("coverm_contig_stats.tsv"), emit: coverm_stats
    path("versions.yml"), emit: versions

    script:
    """
    coverm contig \
	--methods mean trimmed_mean covered_fraction \
	--bam-files ${bam_files} \
	--min-read-percent-identity 95 \
	--threads ${task.cpus} \
  	--output-file coverm_contig_stats.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coverm: \$(coverm --version | sed 's/coverm //')
    END_VERSIONS
    """
}
