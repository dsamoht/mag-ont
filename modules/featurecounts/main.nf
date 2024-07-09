process FEATURECOUNTS {

    conda "bioconda::subread=2.0.1"
    if (workflow.containerEngine == 'singularity') {
        container = params.subread_singularity
    } else {
        container = params.subread_docker
    }

    errorStrategy 'ignore'
    publishDir "${params.outdir}/featurecounts", mode: 'copy'

    input:
    tuple val(meta), path(prodigal_genes_gff)
    tuple val(meta1), path(metaeuk_genes_gff)
    tuple val(meta), path(sorted_bam)
    val read_type

    output:
    tuple val(meta), path("*featureCounts.txt"), emit: counts
    tuple val(meta), path("*featureCounts.txt.summary"), emit: summary

    script:
    if ("${read_type}" == "long") {
        options = "-L -t CDS -g ID -s 0"
    } else {
        options = "-p -t CDS -g ID -s 0"
    }
    """
    cat ${prodigal_genes_gff} ${metaeuk_genes_gff} | grep "CDS" > global_cds.gff 
    featureCounts ${options} -a global_cds.gff -o featureCounts.txt ${sorted_bam}
    """
}
