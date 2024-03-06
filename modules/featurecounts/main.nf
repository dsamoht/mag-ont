process FEATURECOUNTS {

    if (workflow.containerEngine == 'singularity') {
        container = params.subread_singularity
    } else {
        container = params.subread_docker
    }

    errorStrategy 'ignore'
    publishDir "${params.outdir}/featurecounts", mode: 'copy'

    input:
    path prodigal_genes_gff
    path metaeuk_genes_gff
    path sorted_bam
    val read_type

    output:
    path "*featureCounts.txt", emit: counts
    path "*featureCounts.txt.summary", emit: summary

    script:
    if ("${read_type}" == "long") {
        fc_options = "-L -t CDS -g ID -s 0"
    } else {
        fc_options = "-p -t CDS -g ID -s 0"
    }
    """
    cat ${prodigal_genes_gff} ${metaeuk_genes_gff} | grep "CDS" > global_cds.gff 
    featureCounts ${fc_options} -a global_cds.gff -o featureCounts.txt ${sorted_bam}
    """
}
