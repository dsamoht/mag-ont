process SEQKIT_EXCLUDE {

    tag "$meta.id"

    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.13.0--he881be0_0' :
        'biocontainers/seqkit:2.13.0--he881be0_0' }"

    input:
    tuple val(meta), path(assembly), path(sc_mags, stageAs: "sc_mags/*")

    output:
    tuple val(meta), path("*.to_bin.fa"), emit: fasta
    path  "versions.yml"                , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cat sc_mags/* | grep '^>' | sed 's/^>//' | cut -d ' ' -f 1 > sc_mag_ids.txt

    # `seqkit grep` keeps the contig order of the input, which MetaBAT2 requires of the
    # assembly it is given: its depth file is computed from the full assembly and the two
    # are compared in order.
    seqkit \\
        grep \\
        -v \\
        -f sc_mag_ids.txt \\
        --threads $task.cpus \\
        $assembly \\
        > ${prefix}.to_bin.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit version | sed 's/seqkit v//' )
    END_VERSIONS
    """
}
