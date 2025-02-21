process COLLECT {

    publishDir "${params.outdir}/summary", mode: 'copy'

    input:
    path seqkit_tsv
    path checkm_tsv
    path gtdbtk_tsv

    output:
    path "summary.tsv", emit: summary, optional: true

    script:
    """
    #!/usr/bin/env bash
    echo "file,num_seqs,sum_len,min_len,avg_len,max_len,Q1,Q2,Q3,N50,GC(%),completeness,contamination,domain,phylum,class,order,family,genre,species,closest_placement_reference,closest_placement_ani,warnings" > names.tmp
    cat ${seqkit_tsv} | sed '1d' | awk '{print \$1","\$4","\$5","\$6","\$7","\$8","\$9","\$10","\$11","\$13","\$16}' > seqkit.tmp
    cat ${checkm_tsv} | sed '1d' | awk '{print \$13","\$14}' > checkm.tmp
    paste -d, seqkit.tmp checkm.tmp > res1.tmp
    cat ${gtdbtk_tsv} | sed '/^user_genome/d' | awk -F '\t' '{print \$2}' | awk -F ';' '{print \$1","\$2","\$3","\$4","\$5","\$6","\$7}' > taxa.tmp
    cat ${gtdbtk_tsv} | sed '/^user_genome/d' | awk -F '\t' '{print \$8","\$11}' > info1.tmp
    cat ${gtdbtk_tsv} | sed '/^user_genome/d' | awk -F '\t' '{print \$NF}' | sed 's/ /;/g' | sed 's/,/;/g' > info2.tmp
    paste -d, res1.tmp taxa.tmp info1.tmp info2.tmp > val.tmp
    cat names.tmp val.tmp > summary.tsv
    """
}
