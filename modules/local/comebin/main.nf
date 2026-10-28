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

    # An assembly that is empty, too small or too fragmented for COMEBin (no contig over the
    # length cutoff, no marker gene seeds, fewer retained contigs than HNSW neighbours or seeds)
    # has nothing COMEBin can bin. No bins is the right outcome there, so only those failures
    # are let through; any other one fails the task.
    set -o pipefail
    if ! run_comebin.sh \\
        ${args} \\
        -a contigs.fa \\
        -p bams \\
        -o comebin_output \\
        -t ${task.cpus} \\
        -d ${device} 2>&1 | tee comebin.log
    then
        grep -qF \\
            -e 'Input FASTA is missing or empty' \\
            -e 'No sequences were found in' \\
            -e 'No contigs longer than' \\
            -e 'NN training needs at least two contigs' \\
            -e 'received no DataLoader batches' \\
            -e 'FragGeneScan completed but produced no proteins' \\
            -e 'HMMsearch completed but found zero marker hits' \\
            -e 'produced an empty seed set' \\
            -e 'No seed identifiers found in' \\
            -e 'No seed contigs remain on the filtered clustering axis' \\
            -e 'No contigs remain on the clustering axis' \\
            -e 'exceeds the retained contig count' \\
            -e 'max_edges must be between 1 and the retained contig count minus one' \\
            comebin.log || exit 1
        echo "${assembly} is too small for COMEBin: no COMEBin bins" >&2
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
