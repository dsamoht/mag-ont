process COMEBIN {
    
    tag "group_${meta_assembly}"

    container params.comebin_container

    input:
    tuple val(meta_assembly), path(assembly)
    tuple val(meta_bam), path(bam, stageAs: "bam/*")

    output:
    tuple val(meta_assembly), path("comebin_res/comebin_res_bins/*.fa.gz"), emit: bins
    tuple val(meta_assembly), path("comebin_res/comebin_res.tsv")         , emit: tsv
    tuple val(meta_assembly), path("comebin_res/comebin.log")             , emit: log
    tuple val(meta_assembly), path("comebin_res/embeddings.tsv")          , emit: embeddings
    tuple val(meta_assembly), path("comebin_res/covembeddings.tsv")       , emit: covembeddings
    path "versions.yml"                                                   , emit: versions

    script:
    """
    echo run_comebin.sh -t ${task.cpus} \
        -p ./bam \
        -a ${assembly} \
        -o comebin_res

    #find comebin_res/comebin_res_bins/*.fa -exec gzip {} \;

    # avoid file name collisions
    #for filename in comebin_res/comebin_res_bins/*.fa.gz; do
    #    mv "\${filename}" "comebin_res/comebin_res_bins/comebin_res.\$(basename \${filename})"
    #done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        comebin: \$(run_comebin.sh | sed -n 2p | grep -o -E "[0-9]+(\\.[0-9]+)+")
    END_VERSIONS
    """
}
