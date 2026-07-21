process METAMDBG {

    label "large"

    tag "group_${meta.group}"

    container params.metamdbg_container
    
    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.contigs.fasta"), emit: fasta, optional: true
    tuple val(meta), path("*.metaMDBG.log") , emit: log
    path "versions.yml"                     , emit: versions

    script:
    """
    metaMDBG asm \\
        --threads ${task.cpus} \\
        --out-dir . \\
        --in-ont ${reads}

    rm -r tmp/

    gunzip contigs.fasta.gz
    mv contigs.fasta ${meta.group}.contigs.fasta
    mv metaMDBG.log ${meta.group}.metaMDBG.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metamdbg: \$(metaMDBG | grep "Version" | sed 's/ Version: //')
    END_VERSIONS
    """
}
