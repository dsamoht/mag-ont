#!/usr/bin/env python
"""
Join the gtdbtk taxonomic classification of the bins with the contig ID of each contig inside those bins.

usage:
python annotate_bin.py -c [path to contig2bins.tsv, required] -g [path to gtdtk.tsv, required] -o [output file path and name, optional]

output:
contig_taxo_annot.tsv : gtdbtk taxonomic classification for each binned contig
"""
import pandas as pd
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("-b", "--contig2bins", required=True)
ap.add_argument("-g", "--gtdbtk", required=True)
ap.add_argument("-s", "--seqkit", required=True)
ap.add_argument("-c", "--checkm", required=True)
ap.add_argument("-o", "--outdir", required=False, default='.')
args = vars(ap.parse_args())

gtdbk_df = pd.read_csv(args['gtdbtk'], sep='\t', usecols=['user_genome', 'classification'])
contig2bins_df = pd.read_csv(args['contig2bins'], sep='\t', header=None, names=['contigId', 'binId'])
seqkit_df = pd.read_csv(args['seqkit'], sep='\t', usecols=['file', 'num_seqs', 'sum_len', 'N50'])
seqkit_df['file'] = seqkit_df['file'].str.replace('(_sub\.fa|\.fa)', '', regex=True)
checkm_df = pd.read_csv(args['checkm'], sep='\t', usecols=['Bin Id', 'Completeness', 'Contamination'])
checkm_df['Bin Id'] = checkm_df['Bin Id'].str.replace('_sub', '')

is_sub = gtdbk_df['user_genome'].str.contains('_sub', regex=False).rename('is_sub')
gtdbk_df['is_sub'] = is_sub
gtdbk_df['user_genome'] = gtdbk_df['user_genome'].str.replace('_sub', '')

bin_annotation_df = gtdbk_df.merge(right=seqkit_df, left_on='user_genome', right_on='file')
bin_annotation_df = bin_annotation_df.merge(right=checkm_df, left_on='user_genome', right_on='Bin Id')
bin_annotation_df = bin_annotation_df.drop(labels=['file', 'Bin Id'], axis=1)
bin_annotation_df = bin_annotation_df.rename({'user_genome': 'binId'}, axis=1)

contig2bins_df = contig2bins_df.merge(right=bin_annotation_df, left_on='binId', right_on='binId', how='left')
contig2bins_df = contig2bins_df.dropna(axis=0)
contig2bins_df = contig2bins_df.sort_values(by=['is_sub'])
contig2bins_df = contig2bins_df.drop_duplicates(subset=["contigId"], keep="first")
contig2bins_df = contig2bins_df.loc[:, ['contigId', 'binId']]
bin_annotation_df = bin_annotation_df.drop(labels=["is_sub"], axis=1)

bin_annotation_df.to_csv(f"{args['outdir']}/bin_annotation.tsv", sep='\t', index=False)
contig2bins_df.to_csv(f"{args['outdir']}/contigs2bins.tsv", sep='\t', index=False)