process CONCOCT {

    label "medium"

    tag "group_${meta_assembly}"

    container params.concoct_container

    input:
    tuple val(meta_assembly), path(assembly)
    tuple val(meta_bam), path(bam)
    tuple val(meta_bam), path(bai)

    output:
    tuple val(meta_assembly), path("concoct_*.fa"), emit: concoct_bins
    tuple val(meta_assembly), path("contigs_10K.fa"), emit: concoct_contigs
    tuple val(meta_assembly), path("coverage_table.tsv"), emit: concoct_coverage
    path("versions.yml"), emit: versions

    script:
    """
    cut_up_fasta.py ${assembly} -c 10000 -o 0 --merge_last -b contigs_10K.bed > contigs_10K.fa
    concoct_coverage_table.py contigs_10K.bed ${bam.findAll { it.name.endsWith('.bam') }.join(' ')} > coverage_table.tsv
    concoct --composition_file contigs_10K.fa --coverage_file coverage_table.tsv -b concoct_output/ --threads ${task.cpus}
    merge_cutup_clustering.py concoct_output/clustering_gt1000.csv > concoct_output/clustering_merged.csv
    mkdir -p concoct_output/fasta_bins
    extract_fasta_bins.py ${assembly} concoct_output/clustering_merged.csv --output_path concoct_output/fasta_bins

    # Rename all bins to have "concoct_" prefix
    for i in concoct_output/fasta_bins/*.fa; do
        [ -f "\$i" ] || continue
        mv "\$i" "concoct_\$(basename \$i)"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        concoct: \$(echo \$(concoct --version 2> /dev/null) | sed 's/concoct //g' )
    END_VERSIONS
    """
}
