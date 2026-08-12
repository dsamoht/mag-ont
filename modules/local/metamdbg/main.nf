process METAMDBG {

    label 'process_high'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metamdbg:1.4--h3be2455_0' :
        'biocontainers/metamdbg:1.4--h3be2455_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.contigs.fasta"), emit: fasta, optional: true
    tuple val(meta), path("*.metaMDBG.log") , emit: log
    path "versions.yml"                     , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    metaMDBG asm \\
        ${args} \\
        --threads ${task.cpus} \\
        --out-dir . \\
        --in-ont ${reads}

    rm -r tmp/

    gunzip contigs.fasta.gz
    mv contigs.fasta ${prefix}.contigs.fasta
    mv metaMDBG.log ${prefix}.metaMDBG.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metamdbg: \$(metaMDBG | grep "Version" | sed 's/ Version: //')
    END_VERSIONS
    """
}
