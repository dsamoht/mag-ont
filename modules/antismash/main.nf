process ANTISMASH {

    if (workflow.containerEngine == 'singularity') {
        container = params.antismash_singularity
    } else {
        container = params.antismash_docker
    }

     publishDir "${params.outdir}/antismash", mode: 'copy'

     input:
     path assembly

     output:
     path "antismash_out/clusterblast/*_c*.txt", optional: true, emit: clusterblast_file
     path "antismash_out/knownclusterblast/", optional: true, emit: knownclusterblast_dir
     path "antismash_out/knownclusterblast/*_c*.txt" , optional: true, emit: knownclusterblast_txt
     path "antismash_out/clusterblastoutput.txt", optional: true, emit: clusterblastoutput
     path "antismash_out/knownclusterblastoutput.txt", optional: true, emit: knownclusterblastoutput

     script:
     """
     antismash ${assembly} --output-dir antismash_out --genefinding-tool prodigal
     """

}