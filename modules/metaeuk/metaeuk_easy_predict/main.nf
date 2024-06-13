process METAEUK_EASY_PREDICT {

    if (workflow.containerEngine == 'singularity') {
        container = params.metaeuk_singularity
    } else {
        container = params.metaeuk_docker
    }

    publishDir "${params.outdir}/metaeuk", mode: 'copy'
    errorStrategy 'ignore'

    input:
    tuple val(meta), path(euk_contigs)
    path ref_db

    output:
    tuple val(meta), path("euk_genes.fas"), emit: euk_proteins, optional: true
    tuple val(meta), path("euk_genes.codon.fas"), emit: euk_codons, optional: true
    tuple val(meta), path("euk_genes.headersMap.tsv"), emit: euk_headers_map, optional: true
    tuple val(meta), path("euk_genes.gff"), emit: euk_gff, optional: true

    script:
    """
    if [ -s ${euk_contigs} ]; then
        # The file is not-empty.
        metaeuk easy-predict ${euk_contigs} ${ref_db} euk_genes metaeuk_tmp
    else
        # The file is empty.
        touch euk_genes.fas
    fi
    """
}