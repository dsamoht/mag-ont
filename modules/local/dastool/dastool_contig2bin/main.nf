process DASTOOL_CONTIG2BIN {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils:latest"

    input:
    tuple val(meta), val(software), path(bins, stageAs: "input_bins/*")

    output:
    tuple val(meta), path("*_contig2bin.tsv"), emit: contig2bin, optional: true
    path "versions.yml", emit: versions

    script:
    """
    dastool_contig2bin.py ./input_bins ${software}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
        pandas: \$(python3 -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
