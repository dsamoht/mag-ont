process METABAT {

    tag "group_${meta_assembly}"

    container params.metabat_container

    input:
    tuple val(meta_assembly), path(assembly)
    tuple val(meta_bam),      path(bam)

    output:
    tuple val(meta_assembly), path("metabat_bin.*.fa"), emit: metabat_bins, optional: true
    tuple val(meta_assembly), path("group_*_depth.txt"), emit: metabat_depth
    path("versions.yml"), emit: versions

    script:
    """
    jgi_summarize_bam_contig_depths \
        --outputDepth group_${meta_assembly}_depth.txt \
        ${bam}

    metabat2 \
        -i ${assembly}\
        -a group_${meta_assembly}_depth.txt \
        -o metabat_bin

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metabat2: \$( metabat2 --help 2>&1 | head -n 2 | tail -n 1| sed 's/.*\\:\\([0-9]*\\.[0-9]*\\).*/\\1/' )
    END_VERSIONS
    """
}
