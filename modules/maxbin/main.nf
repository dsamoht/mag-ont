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

    contig_count=\$(awk 'BEGIN {RS=">"; FS="\\n"} length(\$2) >= 2500 {print ">" \$0}' ${assembly} | grep -c '^>')

    if [ \$(wc -l < abundances.txt) -gt 2 ] && [ \$contig_count -gt 1 ]; then
        run_MaxBin.pl -min_contig_length 2500 -contig ${assembly} -abund abundances.txt -out maxbin-bin
    else
        awk 'BEGIN {RS=">"; FS="\\n"} length(\$2) >= 2500 {print ">" \$0}' ${assembly} > maxbin-bin.001.fasta
    fi
    """
}
