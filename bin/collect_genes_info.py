#!/usr/bin/env python
"""
usage:
./collect_genes_info.py -f [featureCounts_file] -p [prodigal_aa_file] -o [output_name]

output:
[output_name].counts : table of genes abundance per sample
[output_name].info : genes information (contig, coordinates)
"""

__author__ = "Thomas Deschênes"


import argparse
from collections import defaultdict
from pathlib import Path

import pandas as pd


def main():

    def parse_arguments():
        parser = argparse.ArgumentParser()
        parser.add_argument('-f', '--featureCounts_file', required=True,
                            help='path to the `featureCounts` file')
        parser.add_argument('-p', '--prodigal_aa_file', required=True,
                            help='path to the `prodigal` amino acid file')
        parser.add_argument('-o', '--output_name', required=True,
                            help='basename of output files')
        return parser.parse_args()
    

    featureCounts = Path(parse_arguments().featureCounts_file)
    prodigal = Path(parse_arguments().prodigal_aa_file)

    gene_ID_to_info = defaultdict(dict)

    feature_df = pd.read_csv(featureCounts,
                    skiprows=0,
                    sep="\t",
                    header=1,
                    index_col=0)

    gene_ID_to_number = {}

    with open(prodigal, "r", encoding="utf-8") as prodigal_out:
        count = 0
        for line in prodigal_out:
            if line.startswith(">"):
                count += 1
                id = line.split("ID=")[1].split(";")[0]
                gene_ID_to_number[id] = f"gene_{count}"
                gene_ID_to_info[id]["contig_id"] = line.split()[0].strip(">").rsplit("_", 1)[0]
                gene_ID_to_info[id]["pos"] = line.split()[0].strip(">").rsplit("_", 1)[1]
                gene_ID_to_info[id]["start"] = line.split("#")[1].strip()
                gene_ID_to_info[id]["end"] = line.split("#")[2].strip()


    gene_counts = pd.DataFrame(feature_df.loc[gene_ID_to_number.keys()].iloc[:,5:].rename(gene_ID_to_number))
    gene_counts.index.names = ['gene_id']

    gene_info = pd.DataFrame.from_dict(gene_ID_to_info).transpose().rename(gene_ID_to_number)
    gene_info.index.names = ['gene_id']
    
    gene_info.to_csv(parse_arguments().output_name + ".info")
    gene_counts.to_csv(parse_arguments().output_name + ".counts")

if __name__ == "__main__":
    main()
