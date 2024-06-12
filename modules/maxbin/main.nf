process MAXBIN {

    if (workflow.containerEngine == 'singularity') {
        container = params.maxbin_singularity
    } else {
        container = params.maxbin_docker
    }
    errorStrategy 'ignore'

    input:
    tuple val(meta), path(medakaOutFile)
    tuple val(meta), path(metabatDepth)

    output:
    tuple val(meta), path("*maxbin-bin*.fa*"), emit: maxbinBins, optional: true
    tuple val(meta), path("abundances.txt"), emit: maxbinAbundance

    script:
    """
    cut -f1,4 ${metabatDepth} > abundances.txt
    run_MaxBin.pl -min_contig_length 2500 -contig ${medakaOutFile} -abund abundances.txt -out maxbin-bin
    """
}