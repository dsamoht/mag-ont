#!/usr/bin/env python
"""
Modify featurecounts output by making an abundance table for the predicted genes in the contigs (genes_abundance.tsv)
with id corresponding to hmmsearch and diammond blastp results.

usage:
python genes_abundance_table.py -p [path to featurecount .txt output, required]

output:
genes_abundance.tsv : abundance for each gene
"""
import pandas as pd
import argparse

def main():

    ap = argparse.ArgumentParser()
    ap.add_argument("-p", "--path", required=True)
    args = vars(ap.parse_args())

    df_fc = pd.read_csv(args['path'], sep="\t", skiprows=1)
    pos_contig = df_fc['Geneid'].where(df_fc['Geneid'].str.contains('|', regex=False), '')
    def extract_elements(lst):
        if len(lst) >= 2:
            return (lst[0], lst[-2])
        else:
            return ""
    pos_contig = pos_contig.str.split('|').apply(extract_elements).str.join('_')
    pos_contig = "_" + pos_contig + df_fc['Geneid'].where(pos_contig=="", "").str.split("_").str[-1]
    df_fc.Chr = df_fc.Chr + pos_contig
    df_fc = df_fc.drop(["Geneid", "Start", "End", "Strand",	"Length"], axis=1)
    df_fc = df_fc.rename(columns={"Chr":"geneId"})

    ## Sum all counts columns for each geneId
    # if df_fc.shape[1] > 2:
    #     abund = df_fc.sum(axis=1, numeric_only=True)
    #     df_fc.insert(1, column="Abundance", value=abund)
    #     df_fc = df_fc.iloc[:, df_fc.columns.isin(['geneId','Abundance'])]
    # else:
    #     df_fc = df_fc.rename({df_fc.columns[1]:'Abundance'}, axis=1)

    df_fc = df_fc.rename({df_fc.columns[1]:'Abundance'}, axis=1)
    df_fc = df_fc.iloc[:, df_fc.columns.isin(['geneId','Abundance'])]

    df_fc.to_csv("genes_abundance.tsv", sep="\t", index=False)

if __name__ == "__main__":
    main()