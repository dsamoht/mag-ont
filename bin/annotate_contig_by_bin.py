#!/usr/bin/env python
"""
Join the gtdbtk taxonomic classification of the bins with the contig ID of each contig inside those bins.

usage:
python annotate_contig_by_bin.py -c [path to contig2bins.tsv, required] -g [path to gtdtk.tsv, required] -o [output file path and name, optional]

output:
contig_taxo_annot.tsv : gtdbtk taxonomic classification for each binned contig
"""
import pandas as pd
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("-c", "--contig2bins", required=True)
ap.add_argument("-g", "--gtdbtk", required=True)
ap.add_argument("-o", "--output", required=False, default='./contig_taxo_annot.tsv')
args = vars(ap.parse_args())

gtdbk_df = pd.read_csv(args['gtdbtk'], sep='\t', usecols=['user_genome', 'classification'])

contig2bins_df = pd.read_csv(args['contig2bins'], sep='\t', header=None, names=['contigId', 'binId'])

contig_annotation_df = pd.merge(left=contig2bins_df, right=gtdbk_df, left_on='binId', right_on='user_genome', how='left')
contig_annotation_df = contig_annotation_df.drop(['binId', 'user_genome'], axis=1)
contig_annotation_df = contig_annotation_df.dropna(axis=0)
contig_annotation_df.to_csv(args['output'], sep='\t', index=False)