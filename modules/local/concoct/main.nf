process CONCOCT {

    label 'process_medium'

    tag "$meta_assembly.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/concoct:1.1.0--py311hdfb91c2_8' :
        'biocontainers/concoct:1.1.0--py311hdfb91c2_8' }"

    input:
    tuple val(meta_assembly), path(assembly)
    tuple val(meta_bam), path(bam), path(bai)

    output:
    tuple val(meta_assembly), path("concoct_*.fa")      , emit: concoct_bins, optional: true
    tuple val(meta_assembly), path("contigs_10K.fa")    , emit: concoct_contigs
    tuple val(meta_assembly), path("coverage_table.tsv"), emit: concoct_coverage
    path("versions.yml")                                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    """
    cut_up_fasta.py ${assembly} ${args} -b contigs_10K.bed > contigs_10K.fa
    concoct_coverage_table.py contigs_10K.bed ${bam.findAll { it.name.endsWith('.bam') }.join(' ')} > coverage_table.tsv
    concoct ${args2} --composition_file contigs_10K.fa --coverage_file coverage_table.tsv -b concoct_output/ --threads ${task.cpus}
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
