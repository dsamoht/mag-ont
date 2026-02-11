process GTDBTK {

    label "large"

    tag "group_${meta}"

    container params.gtdbtk_container

    publishDir "${params.outdir}/group_${meta}/binning/gtdbtk", mode: "copy"

    input:
    tuple val(meta), path(bins, stageAs: "bins/*")
    path(gtdbtk_db)

    output:
    tuple val(meta), path("gtdbtk.*.summary.tsv"), emit: gtdbtk_summary, optional: true
    path("versions.yml"), emit: versions

    script:
    """
    export GTDBTK_DATA_PATH=${gtdbtk_db}
    gtdbtk classify_wf \
	--genome_dir bins \
	--out_dir . \
	--skip_ani_screen \
	--extension .fa \
	--cpus ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(echo \$(gtdbtk --version 2>/dev/null) | sed "s/gtdbtk: version //; s/ Copyright.*//")
        gtdb_db: \$(grep VERSION_DATA \$GTDBTK_DATA_PATH/metadata/metadata.txt | sed "s/VERSION_DATA=//")
    END_VERSIONS
    """
}
