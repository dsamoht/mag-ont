process SEMIBIN {

    container "/project/roshab/software/singularity_images/semibin2_2.2.0_jinlongru.sif"

    publishDir "${params.output}/semibin2", mode: 'copy'

    input:
    path assembly
    path bam_files

    output:
    path("semibin_output/output_bins/*.fa"), emit: semibin_bins, optional: true

    script:
    """
    SemiBin2 single_easy_bin -i ${assembly} -b ${bam_files} -o semibin_output --sequencing-type long_read --threads ${task.cpus}

    for f in semibin_output/output_bins/*.fa.gz; do
        [ -f "\$f" ] || continue
        gunzip "\$f"
    done
    """
}