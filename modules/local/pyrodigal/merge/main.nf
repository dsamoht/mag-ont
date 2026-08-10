process MERGE_PYRODIGAL {

    label 'process_single'

    tag "$meta.id"
    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coreutils:9.5' :
        'biocontainers/coreutils:9.5' }"

    input:
    tuple val(meta), path(gffs), path(fnas), path(faas)

    output:
    tuple val(meta), path("*.gff"), emit: gff
    tuple val(meta), path("*.fna"), emit: fna
    tuple val(meta), path("*.faa"), emit: faa
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    head -n1 ${gffs[0]} > ${prefix}.gff
    cat ${gffs} | grep -v '^#' >> ${prefix}.gff

    cat ${fnas} > ${prefix}.fna
    cat ${faas} > ${prefix}.faa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coreutils: \$(cat --version | head -n1 | sed 's/^cat (GNU coreutils) //')
    END_VERSIONS
    """
}
