process GUNZIP {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils@sha256:f0cad0d32d8d8fac7bb971736f158200cf19b4817dd796bd9d76240a054bacf2"

    input:
    tuple val(meta), path(archive)

    output:
    tuple val(meta), path("${archive.baseName}"), emit: file
    path "versions.yml"                         , emit: versions

    script:
    """
    gzip -cd ${archive} > ${archive.baseName}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: \$(gzip --version | head -n1 | sed 's/^gzip //')
    END_VERSIONS
    """
}
