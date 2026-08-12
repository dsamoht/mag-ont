process FLYE {

    label 'process_high'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/flye:2.9.6--py310h275bdba_0' :
        'biocontainers/flye:2.9.6--py310h275bdba_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fasta") , emit: fasta, optional: true
    tuple val(meta), path("*.gfa")   , emit: gfa, optional: true
    tuple val(meta), path("*.txt")   , emit: txt, optional: true
    tuple val(meta), path("*.log")   , emit: log
    tuple val(meta), path("*.json")  , emit: json, optional: true
    path "versions.yml"              , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    flye \
        ${args} \
        --nano-hq ${reads} \
        --threads ${task.cpus} \
        --out-dir .

    mv assembly.fasta ${prefix}.assembly.fasta
    mv assembly_graph.gfa ${prefix}.assembly_graph.gfa
    mv assembly_info.txt ${prefix}.assembly_info.txt
    mv flye.log ${prefix}.flye.log
    mv params.json ${prefix}.params.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$( flye --version )
    END_VERSIONS
    """
}
