process CAT_CONTIGS {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils:latest"

    input:
    tuple val(meta), path(small_fasta), path(lq_fasta), path(mapping_tsv)

    output:
    tuple val(meta), path("${meta.id}.to_bin.fa"), emit: fasta
    path "versions.yml"                          , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    concat_contigs.py \\
        --small ${small_fasta} \\
        --nonhq ${lq_fasta} \\
        --mapping ${mapping_tsv} \\
        --output ${prefix}.to_bin.fa \\
        --wrap 60

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
    END_VERSIONS
    """
}
