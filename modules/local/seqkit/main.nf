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
    tuple val(meta), path("*.large.fa"), emit: large
    tuple val(meta), path("*.small.fa"), emit: small
    path  "versions.yml"               , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def min_len = threshold as Long
    def max_len = (threshold as Long) - 1
    """
    seqkit \\
        seq \\
        -m $min_len \\
        --threads $task.cpus \\
        $fasta \\
        > ${prefix}.large.fa

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
