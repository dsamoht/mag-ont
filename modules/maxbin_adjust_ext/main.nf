process MAXBIN_ADJUST_EXT {

    publishDir "${params.outdir}/maxbin", mode: 'copy'

    input:
    path maxbin_bins

    output:
    path("*maxbin-bin*.fa"), emit: renamed_maxbin_bins, optional: true

    script:
    """
    if [ -n "${maxbin_bins}" ]
    then
        for file in ${maxbin_bins}; do
            [[ \${file} =~ (.*).fasta ]];
            bin="\${BASH_REMATCH[1]}"
            mv \${file} \${bin}.fa
        done
    fi
    """
}