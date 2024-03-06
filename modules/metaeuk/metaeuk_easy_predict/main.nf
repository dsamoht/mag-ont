process METAEUK_EASY_PREDICT {

    if (workflow.containerEngine == 'singularity') {
        container = params.metaeuk_singularity
    } else {
        container = params.metaeuk_docker
    }

    publishDir "${params.outdir}/metaeuk", mode: 'copy'
    

    input:
    path euk_contigs
    path ref_db

    output:
    path "euk_genes.fas", emit: euk_proteins
    path "euk_genes.codon.fas", emit: euk_codons
    path "euk_genes.headersMap.tsv", emit: euk_headers_map
    path "euk_genes.gff", emit: euk_gff

    script:
    """
    metaeuk easy-predict ${euk_contigs} ${ref_db} euk_genes metaeuk_tmp
    """
}