process CAT_CONTIGS {

    label "small"

    tag "group_${meta.group}"

    container params.python_container

    input:
    tuple val(meta), path(small_fasta), path(lq_fasta), path(mapping_tsv)

    output:
    tuple val(meta), path("group_${meta.group}.fa"), emit: unbinned
    
    script:
    """
    concat_contigs.py \\
        --small $small_fasta \\
        --nonhq $lq_fasta \\
        --mapping $mapping_tsv \\
        --output group_${meta.group}.fa \\
        --wrap 60
    """
}
