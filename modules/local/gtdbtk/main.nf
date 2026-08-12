process GTDBTK {

    label 'process_high'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gtdbtk:2.6.1--pyh1f0d9b5_2' :
        'biocontainers/gtdbtk:2.6.1--pyh1f0d9b5_2' }"

    input:
    tuple val(meta), path(bins, stageAs: "bins/*")
    path(gtdbtk_db)

    output:
    tuple val(meta), path("gtdbtk.*.summary.tsv"), emit: gtdbtk_summary, optional: true
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    export GTDBTK_DATA_PATH=${gtdbtk_db}
    gtdbtk classify_wf \
	${args} \
	--genome_dir bins \
	--out_dir . \
	--extension .fa \
	--cpus ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(echo \$(gtdbtk --version 2>/dev/null) | sed "s/gtdbtk: version //; s/ Copyright.*//")
        gtdb_db: \$(grep VERSION_DATA \$GTDBTK_DATA_PATH/metadata/metadata.txt | sed "s/VERSION_DATA=//")
    END_VERSIONS
    """
}
