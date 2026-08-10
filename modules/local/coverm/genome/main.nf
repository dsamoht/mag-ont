process COVERM_GENOME {

    label 'process_medium'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coverm:0.7.0--hcb7b614_4' :
        'biocontainers/coverm:0.7.0--hcb7b614_4' }"

    input:
    tuple val(meta), path(dastool_bins, stageAs: "bins/*"), path(bam_files)

    output:
    tuple val(meta), path("coverm_genome_stats.tsv"), emit: coverm_stats
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    coverm genome \
	${args} \
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
