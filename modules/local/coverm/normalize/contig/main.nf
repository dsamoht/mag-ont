process NORMALIZE_COVERM_CONTIG {

    label 'process_low'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils@sha256:f0cad0d32d8d8fac7bb971736f158200cf19b4817dd796bd9d76240a054bacf2"

    input:
    tuple val(meta), path(coverm_contig_stats), path(gff_file), path(bam_files)

    output:
    tuple val(meta), path("gene_abund_norm.tsv"), emit: gene_abund_norm
    path "versions.yml", emit: versions

    script:
    """
    normalize_coverm_contig.py \
        --input ${coverm_contig_stats} \
        --gff ${gff_file} \
        --bams ${bam_files.join(' ')} \
        --output gene_abund_norm.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
        pandas: \$(python3 -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
