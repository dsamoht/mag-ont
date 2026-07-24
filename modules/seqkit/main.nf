process SEQKIT_SPLITBYLENGTH {

    tag "group_${meta.group}"

    label 'small'
    
    container params.seqkit_container

    input:
    tuple val(meta), path(fasta)
    val threshold

    output:
    tuple val(meta), path("large_contigs/*.fa")              , emit: large, optional: true 
    tuple val(meta), path("${meta.group}_contig_mapping.tsv"), emit: contig_mapping
    tuple val(meta), path("*.small.fa")                      , emit: small
    path  "versions.yml"                                     , emit: versions

    script:
    def min_len = threshold as Long
    def max_len = (threshold as Long) - 1
    """
    mkdir -p large_contigs

    awk '
    /^>/ {
        safe_id = \$1
        sub(/^>/, "", safe_id)
        
        full_name = \$0
        sub(/^>/, "", full_name)
        
        print safe_id "\\t" full_name
    }' $fasta > "${meta.group}_contig_mapping.tsv"

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
        > ${meta.group}.small.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit version | sed 's/seqkit v//' )
    END_VERSIONS
    """
}
