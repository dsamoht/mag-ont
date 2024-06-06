#!/usr/bin/env python
"""
usage:

Make an abundance table for the predicted genes in the contigs (contig_abundance.tsv) which correspond
to hmmer results.
"""
import pandas as pd
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("-p", "--path", required=True)
args = vars(ap.parse_args())

df_fc = pd.read_csv(args['path'], sep="\t", usecols=[0, 1, 6], skiprows=2,
                    names=["Geneid", "Chr", "Abundance"])
pos_contig = df_fc['Geneid'].str.split('_').str[1]
pos_contig = "_" + pos_contig
df_fc.Chr = df_fc.Chr + pos_contig
df_fc = df_fc.drop("Geneid", axis=1)
df_fc = df_fc.rename(columns={"Chr":"contigId"})
df_fc.to_csv("abundance_table.tsv", sep="\t")