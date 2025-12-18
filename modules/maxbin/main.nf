process MAXBIN {

    if (workflow.containerEngine == 'singularity') {
        container = params.maxbin_singularity
    } else {
        container = params.maxbin_docker
    }
    errorStrategy 'ignore'

    input:
    path medakaOutFile
    path metabatDepth

    output:
    path "*maxbin-bin*.fa*", emit: maxbinBins, optional: true
    path "abundances.txt", emit: maxbinAbundance

    script:
    """
    cut -f1,4 ${metabatDepth} > abundances.txt
    run_MaxBin.pl -min_contig_length 2500 -contig ${medakaOutFile} -abund abundances.txt -out maxbin-bin
    """
}