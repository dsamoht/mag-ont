process MAXBIN_ADJUST_EXT {

    errorStrategy 'ignore'

    publishDir "${params.outdir}/maxbin", mode: 'copy'

    input:
    path maxbinBins

    output:
    path "*maxbin-bin*.fa", emit: renamed_maxbinBins, optional: true

    script:
    """
    if [ -n "${maxbinBins}" ]
    then
        for file in ${maxbinBins}; do
            [[ \${file} =~ (.*).fasta ]];
            bin="\${BASH_REMATCH[1]}"
            mv \${file} \${bin}.fa
        done
    fi
    """
}