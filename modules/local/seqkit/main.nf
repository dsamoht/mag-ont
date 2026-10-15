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
    tuple val(meta), path("large_contigs/*.fa", arity: '0..*'), emit: large
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
        # The file name is the ID with anything a path cannot hold replaced, and made unique
        # again if that maps two IDs to one name. The header inside the file is left as is.
        file_id = safe_id
        gsub(/[^A-Za-z0-9._-]/, "_", file_id)
        if (file_id in seen) file_id = file_id "_" NR
        seen[file_id] = 1
        out = "large_contigs/" file_id ".fa"
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
