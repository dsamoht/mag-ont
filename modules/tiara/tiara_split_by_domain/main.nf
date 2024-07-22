process TIARA_SPLIT_BY_DOMAIN {

    publishDir "${params.outdir}/tiara", mode: 'copy'

    input:
    tuple val(meta), path(tiara_classification)
    tuple val(meta), path(contigs)

    output:
    tuple val(meta), path("bac_contigs.fa"), emit: bac_contigs
    tuple val(meta), path("euk_contigs.fa"), emit: euk_contigs

    script:
    """
    grep '^>' ${contigs} > contigs_names
    grep eukarya ${tiara_classification} | sed -E 's/eukarya.*\$//' | sed -E 's/[[:space:]]*\$//' > euk_contigs.txt
    grep organelle ${tiara_classification} | sed -E 's/organelle.*\$//g' | sed -E 's/[[:space:]]*\$//g' >> euk_contigs.txt
    grep -Fvf euk_contigs.txt contigs_names > bac_contigs.txt
    fasta_sampler.py ${contigs} euk_contigs.txt > euk_contigs.fa
    fasta_sampler.py ${contigs} bac_contigs.txt > bac_contigs.fa
    """
}