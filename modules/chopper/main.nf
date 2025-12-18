process CHOPPER {
   
    tag "${meta.sample_id}"

    container params.chopper_container

    publishDir "${params.outdir}/chopper", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.choppered.fastq.gz"), emit: fastq
    path "versions.yml"                          , emit: versions

    script:
    """
    zcat ${reads} \
        | chopper -l 500 --threads ${task.cpus} \
        | chopper -q 10 --threads ${task.cpus} \
        | gzip > ${meta.sample_id}.choppered.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chopper: \$(chopper --version 2>&1 | cut -d ' ' -f 2)
    END_VERSIONS
    """
}
