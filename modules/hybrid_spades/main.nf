process HYBRID_SPADES {

    conda "bioconda::spades=3.15.5"
    if (workflow.containerEngine == 'singularity') {
        container = params.hybridspades_singularity
    } else {
        container = params.hybridspades_docker
    }

    publishDir "${params.outdir}/hybrid_spades", mode: 'copy'

    input:
    tuple val(meta), path(longReads)
    tuple val(sample_id), path(shortReads)

    output:
    tuple val(meta), path("contigs.fna"), emit: assembly
    
    script:
    """
    metaspades.py \
        --threads "${task.cpus}" \
        --pe1-1 ${shortReads[0]} \
        --pe1-2 ${shortReads[1]} \
        --nanopore ${longReads} \
        -o spades
    mv spades/contigs.fasta contigs.fna
    sed -i 's/_length_.*//' contigs.fna
    sed -i 's/>NODE_/>${meta['name']}|NODE_/' contigs.fna
    """
}