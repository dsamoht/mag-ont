process SEQKIT_SPLITBYLENGTH {

    tag "group_${meta.group}"

    label 'small'

    container params.seqkit_container

    input:
    tuple val(meta), path(fasta)
    val threshold

    output:
    tuple val(meta), path("*.large.fa"), emit: large
    tuple val(meta), path("*.small.fa"), emit: small
    path  "versions.yml"               , emit: versions

    script:
    def min_len = threshold as Long
    def max_len = (threshold as Long) - 1
    """
    seqkit \\
        seq \\
        -m $min_len \\
        --threads $task.cpus \\
        $fasta \\
        > ${meta.group}.large.fa

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
