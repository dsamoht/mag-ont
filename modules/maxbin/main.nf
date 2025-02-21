process MAXBIN {

    if (workflow.containerEngine == 'singularity') {
        container = params.maxbin_singularity
    } else {
        container = params.maxbin_docker
    }

    input:
    path assembly 
    path metabat_depth

    output:
    path("*maxbin-bin*.fa*"), emit: maxbin_bins, optional: true
    path("abundances.txt"), emit: maxbin_abundance

    script:
    """
    cut -f1,4 ${metabat_depth} > abundances.txt
    run_MaxBin.pl -min_contig_length 2500 -contig ${assembly} -abund abundances.txt -out maxbin-bin
    """
}