process PYRODIGAL {
    
    label 'process_medium'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pyrodigal:3.7.0--py311haab0aaa_0' :
        'biocontainers/pyrodigal:3.7.0--py311haab0aaa_0' }"

    input:
    tuple val(meta), val(chunk_idx), path(fasta)

    output:
    tuple val(meta), val(chunk_idx), path("*.gff"), path("*.fna"), path("*.faa"), emit: genes
    path "versions.yml"                                                         , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    pyrodigal \\
        -i ${fasta} \\
        -f gff \\
        -o ${prefix}.chunk${chunk_idx}.gff \\
        -d ${prefix}.chunk${chunk_idx}.fna \\
        -a ${prefix}.chunk${chunk_idx}.faa \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pyrodigal: \$(echo \$(pyrodigal --version 2>&1 | sed 's/pyrodigal v//'))
    END_VERSIONS
    """
}
