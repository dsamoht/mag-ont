process PYRODIGAL {
    
    label "medium"

    tag "group_${meta}"

    container params.pyrodigal_container

    input:
    tuple val(meta), val(chunk_idx), path(fasta)

    output:
    tuple val(meta), path("*.gff") , emit: gff
    tuple val(meta), path("*.fna") , emit: fna
    tuple val(meta), path("*.faa") , emit: faa
    path "versions.yml"            , emit: versions

    script:
    """
    pyrodigal \\
        -j ${task.cpus} \\
        -i ${fasta} \\
        -f gff \\
        -o group_${meta}.chunk${chunk_idx}.gff \\
        -d group_${meta}.chunk${chunk_idx}.fna \\
        -a group_${meta}.chunk${chunk_idx}.faa \\
        -p meta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pyrodigal: \$(echo \$(pyrodigal --version 2>&1 | sed 's/pyrodigal v//'))
    END_VERSIONS
    """
}
