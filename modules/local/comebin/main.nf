process COMEBIN {

    label 'process_high'
    label 'process_gpu'

    tag "$meta.id"

    container "docker.io/dsamoht/comebin:1.1.0"

    input:
    tuple val(meta), path(assembly)
    tuple val(bam_meta), path(bams, stageAs: 'bams/*')

    output:
    tuple val(meta), path("comebin_*.fa", arity: '0..*'), emit: comebin_bins
    path("versions.yml")                 , emit: versions

    script:
    def args = task.ext.args ?: ''
    def device = task.ext.use_gpu ? 'cuda' : 'cpu'
    """
    # COMEBin resolves the assembly path and writes its marker-gene seed files next to it:
    # through the staged symlink that would be the upstream task's directory.
    cp -L ${assembly} contigs.fa

    # COMEBin clusters from single-copy marker gene seeds: an assembly too small or too
    # fragmented to yield a seed set has nothing COMEBin can bin. No bins is the right
    # outcome there, so only that failure is let through; any other one fails the task.
    if ! run_comebin.sh \\
        ${args} \\
        -a contigs.fa \\
        -p bams \\
        -o comebin_output \\
        -t ${task.cpus} \\
        -d ${device}
    then
        grep -qs 'no usable marker seed set could be generated' contigs.fa.bacar_marker.2quarter_lencutoff_1001.seed.err || exit 1
        echo "${assembly} yields no marker gene seeds: no COMEBin bins" >&2
    fi

    for f in comebin_output/comebin_res/comebin_res_bins/*.fa; do
        [ -f "\$f" ] || continue
        mv "\$f" "comebin_\$(basename \$f)"
    done

    # The trained model checkpoint alone is hundreds of MB; only the bins are emitted
    rm -rf comebin_output contigs.fa*

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        comebin: \$( run_comebin.sh -V | sed 's/COMEBin version: //' )
    END_VERSIONS
    """
}
