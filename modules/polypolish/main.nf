process POLYPOLISH {

    conda "bioconda::polypolish=0.5.0"
    if (workflow.containerEngine == 'singularity') {
        container = params.polypolish_singularity
    } else {
        container = params.polypolish_docker
    }

    publishDir "${params.outdir}/polypolish", mode: 'copy'
    
    input:
    tuple val(meta), path(inputAssembly)
    tuple val(meta), path(fwdSam)
    tuple val(meta), path(revSam)
    
    output:
    tuple val(meta), path('consensus_polished.fasta'), emit: polishedAssembly

    script:
    """
    polypolish_insert_filter.py --in1 ${fwdSam} --in2 ${revSam} --out1 filtered_1.sam --out2 filtered_2.sam
    polypolish ${inputAssembly} filtered_1.sam filtered_2.sam > consensus_polished.fasta
    """
}