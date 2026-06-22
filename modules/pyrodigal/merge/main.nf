process MERGE_PYRODIGAL {

    label "small"

    tag "group_${meta}"
    
    container params.coreutils_container

    input:
    tuple val(meta), path(gffs), path(fnas), path(faas)

    output:
    tuple val(meta), path("group_${meta}.gff"), emit: gff
    tuple val(meta), path("group_${meta}.fna"), emit: fna
    tuple val(meta), path("group_${meta}.faa"), emit: faa

    script:
    """
    head -n1 ${gffs[0]} > group_${meta}.gff
    cat ${gffs} | grep -v '^#' >> group_${meta}.gff

    cat ${fnas} > group_${meta}.fna
    cat ${faas} > group_${meta}.faa
    """
}
