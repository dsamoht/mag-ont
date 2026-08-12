process SEQKIT_SPLITBYLENGTH {

    tag "$meta.id"

    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.13.0--he881be0_0' :
        'biocontainers/seqkit:2.13.0--he881be0_0' }"

    input:
    tuple val(meta), path(fasta)
    val threshold

    output:
    tuple val(meta), path("large_contigs/*.fa")  , emit: large, optional: true
    tuple val(meta), path("*_contig_mapping.tsv"), emit: contig_mapping
    tuple val(meta), path("*.small.fa")          , emit: small
    path  "versions.yml"                         , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def min_len = threshold as Long
    def max_len = (threshold as Long) - 1
    """
    mkdir -p large_contigs

    # Each long contig goes to its own file, named after the contig ID alone, so that it
    # can be assessed as a genome in its own right. The full header is recorded here so it
    # can be restored on the contigs that are put back together for binning.
    awk '
    /^>/ {
        safe_id = \$1
        sub(/^>/, "", safe_id)

        full_name = \$0
        sub(/^>/, "", full_name)

        print safe_id "\\t" full_name
    }' $fasta > ${prefix}_contig_mapping.tsv

    seqkit \\
        seq \\
        -m $min_len \\
        --threads $task.cpus \\
        $fasta | \\
    awk '
    /^>/ {
        if (out) close(out)
        safe_id = \$1
        sub(/^>/, "", safe_id)
        out = "large_contigs/" safe_id ".fa"
        print \$0 > out
        next
    }
    { if (out) print \$0 >> out }'

    seqkit \\
        seq \\
        -M $max_len \\
        --threads $task.cpus \\
        $fasta \\
        > ${prefix}.small.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit version | sed 's/seqkit v//' )
    END_VERSIONS
    """
}
