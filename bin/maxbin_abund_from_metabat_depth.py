#!/usr/bin/env python
import sys

import pandas as pd


def main(metabat_depth: str):
    """Convert metabat depth file to MaxBin2 abundance format.
    args:
        metabat_depth : Path to the metabat depth.txt file.
    """
    df = pd.read_csv(metabat_depth, sep="\t")
    cols_to_keep = [col for col in df.columns if not col.endswith("-var") and col not in ["contigLen", "totalAvgDepth"]]
    df_clean = df[cols_to_keep]
    df_clean.to_csv("maxbin_abund.txt", sep="\t", index=False, header=True)


if __name__ == "__main__":
    metabat_depth = sys.argv[1]
    main(metabat_depth)