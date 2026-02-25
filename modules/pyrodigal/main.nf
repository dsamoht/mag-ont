process PYRODIGAL {
    
    label "medium"

    tag "group_${meta}"

    container params.pyrodigal_container

    publishDir "${params.outdir}/group_${meta}/assembly/pyrodigal", mode: "copy"

    input:
    tuple val(meta), path(fasta)

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
        -o group_${meta}.gff \\
        -d group_${meta}.fna \\
        -a group_${meta}.faa \\
        -p meta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pyrodigal: \$(echo \$(pyrodigal --version 2>&1 | sed 's/pyrodigal v//'))
    END_VERSIONS
    """
}
