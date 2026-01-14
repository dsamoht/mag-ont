process MEDAKA {

    tag "group_${meta.group}"

    container params.medaka_container

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.consensus.fasta"), emit: fasta
    path "versions.yml"                       , emit: versions

    script:
    """
    medaka_consensus \
        -t ${task.cpus} \
        -i ${reads} \
        -d ${assembly} \
        -o ./

    mv consensus.fasta ${meta.group}.consensus.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
