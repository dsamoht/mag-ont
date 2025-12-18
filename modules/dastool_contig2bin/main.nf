process DASTOOL_CONTIG2BIN {

    container "/project/roshab/software/singularity_images/pandas_2.2.1.sif"

    publishDir "${params.output}/dastool", mode: 'copy'

    input:
    tuple path(bins, stageAs: "input_bins/*"), val(software)

    output:
    path("*_contig2bin.tsv"), emit: contig2bin, optional: true

    script:
    """
    #!/usr/bin/env python
    import os
    import sys

    def parse_fasta_headers(fpath, bin_name):
        with open(fpath) as f:
            for line in f:
                if line.startswith(">"):
                    contig = line[1:].strip().split()[0]
                    yield contig, bin_name

    out_file = "${software}_contig2bin.tsv"

    with open(out_file, "w") as out:
        for fname in sorted(os.listdir("input_bins")):
            if not fname.lower().endswith((".fa", ".fna", ".fasta", ".fa.gz", ".fna.gz", ".fasta.gz")):
                continue
            bin_name = os.path.splitext(os.path.basename(fname))[0]
            if bin_name.endswith(".fa") or bin_name.endswith(".fna") or bin_name.endswith(".fasta"):
                bin_name = bin_name.rsplit(".", 1)[0]
            for contig, b in parse_fasta_headers(os.path.join("input_bins", fname), bin_name):
                out.write(f"{contig}\\t{b}\\n")
    """
}
