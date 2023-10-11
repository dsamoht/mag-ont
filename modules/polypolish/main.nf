process POLYPOLISH {

    if (workflow.containerEngine == 'singularity') {
        container = params.polypolish_singularity
    } else {
        container = params.polypolish_docker
    }

    publishDir "${params.outdir}/polypolish", mode: 'copy'
    
    input:
    path inputAssembly
    path fwdSam
    path revSam
    
    output:
    path 'consensus_polished.fasta', emit: polishedAssembly

    script:
    """
    polypolish_insert_filter.py --in1 ${fwdSam} --in2 ${revSam} --out1 filtered_1.sam --out2 filtered_2.sam
    polypolish ${inputAssembly} filtered_1.sam filtered_2.sam > consensus_polished.fasta
    """
}