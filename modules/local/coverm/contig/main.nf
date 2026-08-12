process COVERM_CONTIG {

    label 'process_medium'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coverm:0.7.0--hcb7b614_4' :
        'biocontainers/coverm:0.7.0--hcb7b614_4' }"

    input:
    tuple val(meta), path(bam_files)

    output:
    tuple val(meta), path("coverm_contig_stats.tsv"), emit: coverm_stats
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    coverm contig \
	${args} \
	--bam-files ${bam_files} \
	--threads ${task.cpus} \
  	--output-file coverm_contig_stats.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coverm: \$(coverm --version | sed 's/coverm //')
    END_VERSIONS
    """
}
