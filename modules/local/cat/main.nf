process CAT_FASTQ {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coreutils:9.5' :
        'biocontainers/coreutils:9.5' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.merged.fastq.gz"), emit: reads
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def readList = reads instanceof List ? reads.collect { it.toString() } : [reads.toString()]

    if (readList.size >= 1) {
    """
    cat ${readList.join(' ')} > ${prefix}.merged.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coreutils: \$(cat --version | head -n1 | sed 's/^cat (GNU coreutils) //')
    END_VERSIONS
    """
    }
}
