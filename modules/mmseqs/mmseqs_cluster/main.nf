process MMSEQS_CLUSTER {

    if (workflow.containerEngine == 'singularity') {
        container = params.mmseqs_singularity
    } else {
        container = params.mmseqs_docker
    }

    publishDir "${params.outdir}/mmseqs", mode: 'copy'
    
    input:
    path proteins
    path database
    
    
    output:
    path 'prot_and_db_mmseqs_clu*'

    script:
    """
    sed "s/^>/>SAMPLE|/g" ${proteins} > proteins.faa
    sed "s/^>/>DB|/g" ${database} > database.faa
    cat proteins.faa database.faa > prot_and_db.fasta
    mmseqs createdb prot_and_db.fasta prot_and_db_mmseqs
    mmseqs cluster prot_and_db_mmseqs prot_and_db_mmseqs_clu tmp
    mmseqs createtsv prot_and_db_mmseqs prot_and_db_mmseqs prot_and_db_mmseqs_clu prot_and_db_mmseqs_clu.tsv
    """
}