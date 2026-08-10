process PORECHOP_ABI {

    label 'process_medium'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/porechop_abi:0.5.1--py39h475c85d_0' :
        'biocontainers/porechop_abi:0.5.1--py39h475c85d_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads
    tuple val(meta), path("*.log")     , emit: log
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    porechop_abi \
        ${args} \
        -i ${reads} \
        -o ${prefix}.porechopped.fastq.gz > ${prefix}.porechop.log
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        porechop_abi: \$( porechop_abi --version )
    END_VERSIONS
    """
}
