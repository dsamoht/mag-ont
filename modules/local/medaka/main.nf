process MEDAKA {

    label 'process_high'
    label 'process_gpu'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/medaka:2.1.1--py310h5713b5a_0' :
        'biocontainers/medaka:2.1.1--py310h5713b5a_0' }"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.consensus.fasta"), emit: fasta
    path "versions.yml"                       , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    medaka_consensus \
        ${args} \
        -t ${task.cpus} \
        -i ${reads} \
        -d ${assembly} \
        -o ./

    mv consensus.fasta ${prefix}.consensus.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
