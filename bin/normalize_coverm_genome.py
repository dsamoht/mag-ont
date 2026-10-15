#!/usr/bin/env python3

import pandas as pd
import argparse

"""
sample-wise normalization of coverM genome statistics.

-> Formula : mean (or trimmed mean) * (1,000,000 / total aligned nucleotides)
-> Result interpretation: mean (or trimmed mean) coverage per million aligned bases
"""

def read_aligned_bases(depth_files):
    """sample -> aligned bases, from the `<sample>\t<bases>` files written by the mappers."""
    sample_depths = {}
    for depth_file in depth_files:
        with open(depth_file) as f:
            for line in f:
                sample, bases = line.rstrip("\n").split("\t")
                sample_depths[sample] = int(bases)
                print(f" - {sample}: {bases} bp")
    return sample_depths


def normalize_coverm_genome(coverm_tsv, depth_files, output_file):
    # 1. Total aligned nucleotides of each sample
    sample_depths = read_aligned_bases(depth_files)

    # 2. Load CoverM results
    df = pd.read_table(coverm_tsv)

    # 3. Apply normalization. CoverM names its columns "<sample> <metric>": match them
    # exactly, a substring match would pair "S10 Mean" with the depth of sample "S1"
    for sample, total_depth in sample_depths.items():
        for metric in ("Mean", "Trimmed Mean"):
            col = f"{sample} {metric}"
            if col not in df.columns:
                continue
            new_col_name = f"{col}_norm_per_bp"
            if total_depth > 0:
                df[new_col_name] = df[col] * (1_000_000 / total_depth)
            else:
                df[new_col_name] = 0

    df.to_csv(output_file, sep="\t", index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="normalize CoverM genome statistics by sample nucleotide depth.")
    parser.add_argument("-i", "--input", required=True, help="tsv output from CoverM Genome.")
    parser.add_argument("-d", "--depths", required=True, nargs='+', help="aligned bases file(s), one '<sample>\\t<bases>' line each.")
    parser.add_argument("-o", "--output", required=True, help="output tsv file name.")

    args = parser.parse_args()
    normalize_coverm_genome(args.input, args.depths, args.output)
