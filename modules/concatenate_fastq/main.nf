process CONCATENATE_FASTQ {

    input:
    path new_fastq_file
    path all_fastq_files, stageAs: "all_fastqs/*"

    output:
    path "fastq_files_concatenated"

    script:
    """
    ls all_fastqs/* > fastq_files_concatenated
    """
}