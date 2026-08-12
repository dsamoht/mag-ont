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
    jgi_summarize_bam_contig_depths \\
        --outputDepth ${prefix}_depth_all.txt \\
        ${bam}

    # Reads are mapped against the full assembly, so the depth file covers contigs this
    # process is not given - the single-contig MAGs held out of binning. MetaBAT2 compares
    # the two in order and refuses a mismatch, so keep only the contigs of this assembly,
    # in its own order.
    grep '^>' ${assembly} | sed 's/^>//; s/[[:space:]].*//' > contig_order.txt

    awk 'NR==FNR { order[\$1] = ++n; next }
        FNR==1  { print; next }
        (\$1 in order) { rows[order[\$1]] = \$0 }
        END { for (i = 1; i <= n; i++) if (i in rows) print rows[i] }' \\
        contig_order.txt ${prefix}_depth_all.txt > ${prefix}_depth.txt

    metabat2 \\
        ${args} \\
        -i ${assembly} \\
        -a ${prefix}_depth.txt \\
        -o metabat_bin

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metabat2: \$( metabat2 --help 2>&1 | head -n 2 | tail -n 1| sed 's/.*\\:\\([0-9]*\\.[0-9]*\\).*/\\1/' )
    END_VERSIONS
    """
}
