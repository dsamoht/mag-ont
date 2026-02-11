process SEMIBIN {

    label "large_gpu"

    tag "group_${meta}"

    container params.semibin_container

    input:
    tuple val(meta), path(assembly)
    tuple val(bam_meta), path(bams)
    val(strategy_type)

    output:
    tuple val(meta), path("semibin_output/output_bins/*.fa"), emit: semibin_bins, optional: true
    path("versions.yml"), emit: versions

    script:
    def type_flag = strategy_type == 'long' ? '--sequencing-type long_read' : ''
    """
    SemiBin2 single_easy_bin \
        -i ${assembly} \
        -b ${bams} \
        -o semibin_output \
        --threads ${task.cpus} \
         ${type_flag}

    for f in semibin_output/output_bins/*.fa.gz; do
        [ -f "\$f" ] || continue
        gunzip "\$f"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        SemiBin: \$( SemiBin2 --version )
    END_VERSIONS
    """
}
