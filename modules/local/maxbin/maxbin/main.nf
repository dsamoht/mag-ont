process MAXBIN {

    label 'process_high'

    tag "$meta_assembly.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/maxbin2:2.2.7--hdbdd923_5' :
        'biocontainers/maxbin2:2.2.7--hdbdd923_5' }"

    input:
    tuple val(meta_assembly), path(assembly)
    tuple val(meta), path(maxbin_abund)

    output:
    tuple val(meta_assembly), path("maxbin_bin.*.fasta"), emit: maxbin_bins, optional: true
    path("versions.yml")                                , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    # MaxBin needs at least two seed contigs to cluster: on a single-contig assembly its
    # core binary aborts right after reading the seed list. No bins is the right outcome
    # there, so skip the run instead of failing the group.
    if [ \$(grep -c '^>' ${assembly}) -ge 2 ]; then
        run_MaxBin.pl \
            ${args} \
            -contig ${assembly} \
            -abund ${maxbin_abund} \
            -out maxbin_bin
    else
        echo "${assembly} has fewer than 2 contigs: skipping MaxBin" >&2
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        maxbin2: \$( run_MaxBin.pl -v | head -n 1 | sed 's/MaxBin //' )
    END_VERSIONS
    """
}
