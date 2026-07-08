process MAXBIN {

    label "large"

    tag "group_${meta_assembly}"

    container params.maxbin_container

    input:
    tuple val(meta_assembly), path(assembly)
    tuple val(meta), path(maxbin_abund)

    output:
    tuple val(meta_assembly), path("maxbin_bin.*.fasta"), emit: maxbin_bins, optional: true
    path("versions.yml"), emit: versions

    script:
    """
    run_MaxBin.pl \
        -min_contig_length ${params.maxbin_minlen} \
        -contig ${assembly} \
        -abund ${maxbin_abund} \
        -out maxbin_bin

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        maxbin2: \$( run_MaxBin.pl -v | head -n 1 | sed 's/MaxBin //' )
    END_VERSIONS
    """
}
