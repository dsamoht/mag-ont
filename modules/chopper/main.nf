process CHOPPER {

    if (workflow.containerEngine == 'singularity') {
        container = params.chopper_singularity
    } else {
        container = params.chopper_docker
    }
    
    //errorStrategy 'ignore'

    publishDir "${params.outdir}/chopper", mode: 'copy'

    input:
    path raw_reads

    output:
    path "qc_reads.fastq.gz", emit: qc_reads

    script:
    """
    zcat ${raw_reads} | chopper --headcrop 40 -l 500 -q 10 --threads ${task.cpus} | gzip > qc_reads.fastq.gz
    """
}
