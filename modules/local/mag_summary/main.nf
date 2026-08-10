process MAG_SUMMARY {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils:latest"

    input:
    tuple val(meta), path(dastool_bins), path(checkm_stats), path(gtdbtk_res), path(coverm_stats)

    output:
    tuple val(meta), path("*_mag_summary.csv"), emit: mag_summary
    tuple val(meta), path("*_contig2bin.csv"), emit: contig2bin
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    // `gtdbtk_res` is empty when GTDB-Tk is skipped, and a glob output is a single path
    // rather than a list when it matched exactly one file: normalize both here.
    def bins        = dastool_bins instanceof List ? dastool_bins : [ dastool_bins ]
    def gtdbtk_out  = gtdbtk_res instanceof List ? gtdbtk_res : [ gtdbtk_res ]
    def gtdbtk_bac  = gtdbtk_out.find { f -> f.name.contains('bac120') }
    def gtdbtk_ar   = gtdbtk_out.find { f -> f.name.contains('ar53') }
    def gtdbtk_args = [
        gtdbtk_bac ? "--bac120 ${gtdbtk_bac}" : '',
        gtdbtk_ar  ? "--ar53 ${gtdbtk_ar}"    : ''
    ].findAll().join(' ')
    """
    mag_summary.py \
        --bins ${bins.join(' ')} \
        --checkm ${checkm_stats} \
        --coverm ${coverm_stats} \
        ${gtdbtk_args} \
        --group ${prefix} \
        --output ${prefix}_mag_summary.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
        pandas: \$(python3 -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
