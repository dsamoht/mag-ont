process METABAT {

    label 'process_medium'

    tag "$meta_assembly.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metabat2:2.15--h4da6f23_2' :
        'biocontainers/metabat2:2.15--h4da6f23_2' }"

    input:
    tuple val(meta_assembly), path(assembly)
    tuple val(meta_bam),      path(bam)

    output:
    tuple val(meta_assembly), path("metabat_bin.*.fa"), emit: metabat_bins, optional: true
    tuple val(meta_assembly), path("*_depth.txt"), emit: metabat_depth
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta_assembly.id}"
    """
    jgi_summarize_bam_contig_depths \
        --outputDepth ${prefix}_depth.txt \
        ${bam}

    metabat2 \
        ${args} \
        -i ${assembly} \
        -a ${prefix}_depth.txt \
        -o metabat_bin

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metabat2: \$( metabat2 --help 2>&1 | head -n 2 | tail -n 1| sed 's/.*\\:\\([0-9]*\\.[0-9]*\\).*/\\1/' )
    END_VERSIONS
    """
}
