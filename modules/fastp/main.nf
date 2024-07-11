process FASTP {

    conda "bioconda::fastp=0.23.4"
    if (workflow.containerEngine == 'singularity') {
        container = params.fastp_singularity
    } else {
        container = params.fastp_docker
    }
    
    //errorStrategy 'ignore'

    publishDir "${params.outdir}/fastp", mode: 'copy'

    input:
    tuple val(meta), path(raw_reads)

    output:
    tuple val(meta), path("out_R{1,2}.fastq.gz"), emit: qc_reads

    script:
    """
    fastp -i ${raw_reads[0]} -I ${raw_reads[1]} --thread ${task.cpus} -o out_R1.fastq.gz -O out_R2.fastq.gz
    """
}