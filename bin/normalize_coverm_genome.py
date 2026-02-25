#!/usr/bin/env python3

import pandas as pd
import pysam
import os
import argparse

"""
sample-wise normalization of coverM genome statistics.

-> Formula : mean (or trimmed mean) * (1,000,000 / total aligned nucleotides)
-> Result interpretation: mean (or trimmed mean) coverage per million aligned bases
"""

def normalize_coverm_genome(coverm_tsv, bam_files, output_file):
    # 1. Calculate total aligned nucleotides for each BAM
    sample_depths = {}
    for bam in bam_files:
        sample_name = os.path.basename(bam).rsplit('.', 1)[0]
        with pysam.AlignmentFile(bam, "rb") as sam:
            # Sum of aligned lengths (excludes unmapped reads and soft-clips)
            sample_depths[sample_name] = sum(r.query_alignment_length for r in sam if not r.is_unmapped)
            print(f" - {sample_name}: {sample_depths[sample_name]} bp")

    # 2. Load CoverM results
    df = pd.read_table(coverm_tsv)
    
    # 3. Apply normalization
    for col in df.columns:
        for sample, total_depth in sample_depths.items():
            # Match columns containing the sample name and the metrics
            if sample in col and ("Mean" in col or "Trimmed Mean" in col):
                new_col_name = f"{col}_norm_per_bp"
                if total_depth > 0:
                    df[new_col_name] = df[col] * (1_000_000 / total_depth)
                else:
                    df[new_col_name] = 0

    df.to_csv(output_file, sep="\t", index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="normalize CoverM genome statistics by sample nucleotide depth.")
    parser.add_argument("-i", "--input", required=True, help="tsv output from CoverM Genome.")
    parser.add_argument("-b", "--bams", required=True, nargs='+', help="bam file(s).")
    parser.add_argument("-o", "--output", required=True, help="output tsv file name.")

    args = parser.parse_args()
    normalize_coverm_genome(args.input, args.bams, args.output)
