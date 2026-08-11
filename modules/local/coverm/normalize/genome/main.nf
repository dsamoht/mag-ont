process NORMALIZE_COVERM_GENOME {

    label 'process_low'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils@sha256:f0cad0d32d8d8fac7bb971736f158200cf19b4817dd796bd9d76240a054bacf2"

    input:
    tuple val(meta), path(coverm_genome_stats), path(bam_files)

    output:
    tuple val(meta), path("coverm_genome_stats_norm.tsv"), emit: coverm_genome_norm
    path "versions.yml", emit: versions

    script:
    """
    normalize_coverm_genome.py \
        --input ${coverm_genome_stats} \
        --bams ${bam_files.join(' ')} \
        --output coverm_genome_stats_norm.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
        pandas: \$(python3 -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
