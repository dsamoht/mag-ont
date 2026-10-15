process MEDAKA {

    label 'process_high'
    label 'process_gpu'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/medaka:2.1.1--py310h5713b5a_0' :
        'biocontainers/medaka:2.1.1--py310h5713b5a_0' }"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.consensus.fasta"), emit: fasta
    path "versions.yml"                       , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # medaka_consensus resolves the draft path and indexes it in place: through the staged
    # symlink the .fai and minimap2 index would land in the assembler's task directory.
    cp -L ${assembly} draft.fasta

    medaka_consensus \
        ${args} \
        -t ${task.cpus} \
        -i ${reads} \
        -d draft.fasta \
        -o ./

    mv consensus.fasta ${prefix}.consensus.fasta

    # The read alignment to the draft is on the scale of the read set; it, the inference
    # probabilities and the draft with its indexes are not used past the consensus
    rm -rf draft.fasta* calls_to_draft.* consensus_probs.hdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
