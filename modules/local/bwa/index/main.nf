process BWA_INDEX {

    label 'process_medium'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:8f3ad900103a4eb7fde71bb8b4841b1f18683f3f-0' :
        'biocontainers/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:8f3ad900103a4eb7fde71bb8b4841b1f18683f3f-0' }"

    input:
    tuple val(meta), path(reference)

    output:
    tuple val(meta), path("bwa_index"), emit: index
    path("versions.yml")              , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    mkdir bwa_index
    bwa-mem2 index \\
        ${args} \\
        -p bwa_index/${meta.id} \\
        ${reference}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa-mem2: \$(echo \$(bwa-mem2 version 2>&1 | tail -1))
    END_VERSIONS
    """
}
