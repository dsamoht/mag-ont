process SEMIBIN {

    label 'process_high'
    label 'process_gpu'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/jinlongru/semibin2:v2.2.0.0"

    input:
    tuple val(meta), path(assembly)
    tuple val(bam_meta), path(bams)
    val(strategy_type)

    output:
    tuple val(meta), path("semibin_output/output_bins/*.fa", arity: '0..*'), emit: semibin_bins
    path("versions.yml")                                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    def type_flag = strategy_type == 'long' ? '--sequencing-type long_read' : ''
    """
    # SemiBin2 refuses an assembly with fewer than 4 contigs long enough to bin, which the
    # assembly left once the single-contig MAGs are held out can be. No bins is the right
    # outcome there, so only that failure is let through; any other one fails the task.
    status=0
    SemiBin2 single_easy_bin \
        ${args} \
        -i ${assembly} \
        -b ${bams} \
        -o semibin_output \
        --threads ${task.cpus} \
        ${type_flag} \
        2> semibin.stderr \
        || status=\$?
    cat semibin.stderr >&2

    if [ \$status -ne 0 ]; then
        grep -qE 'but all are shorter than|but only [0-9]+ contain.s. at least' semibin.stderr || exit \$status
        echo "${assembly} has too few contigs long enough for SemiBin2: no SemiBin2 bins" >&2
    fi

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
