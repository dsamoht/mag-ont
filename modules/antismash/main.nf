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
     path "./clusterblast/*_c*.txt", optional: true, emit: clusterblast_file
     path "./knownclusterblast/", optional: true, emit: knownclusterblast_dir
     path "./knownclusterblast/*_c*.txt" , optional: true, emit: knownclusterblast_txt
     path "./clusterblastoutput.txt", optional: true, emit: clusterblastoutput
     path "./knownclusterblastoutput.txt", optional: true, emit: knownclusterblastoutput

     script:
     """
     antismash ${assembly} --output-dir . --genefinding-tool prodigal
     """

}