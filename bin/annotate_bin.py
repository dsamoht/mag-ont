#!/usr/bin/env python
"""
Join the gtdbtk taxonomic classification of the bins with the contig ID of each contig inside those bins.

usage:
python annotate_bin.py -b [path to contig2bins.tsv, required] -g [path to gtdtk.tsv, optional] -s [path to seqkit tsv output, optional] -c [path to checkm tsv output, optional] -o [output directory path, default current directory]

output:
contigs2bins.tsv : contig2bins tsv file with all binned contigs and their associated binId
bin_annotation.tsv : summary of gtdb-tk, checkm and seqkit annotation for each bin
"""
import pandas as pd
import argparse
import os

def main():

    ap = argparse.ArgumentParser()
    ap.add_argument("-b", "--contig2bins", required=True)
    ap.add_argument("-g", "--gtdbtk", required=False)
    ap.add_argument("-s", "--seqkit", required=True)
    ap.add_argument("-c", "--checkm", required=True)
    ap.add_argument("-o", "--outdir", required=False, default='.')
    args = vars(ap.parse_args())

    gtdbk_df = pd.DataFrame(columns=["binId"], dtype=float)
    if args['gtdbtk'] != None and os.stat(args['gtdbtk']).st_size != 0:
        gtdbk_df = pd.read_csv(args['gtdbtk'], sep='\t', usecols=['user_genome', 'classification'])
        gtdbk_df = gtdbk_df.rename({'user_genome': 'binId'}, axis=1)
        gtdbk_df['binId'] = gtdbk_df['binId'].str.replace('_sub', '')

    contig2bins_df = pd.read_csv(args['contig2bins'], sep='\t', header=None, names=['contigId', 'binId'])

    seqkit_df = pd.read_csv(args['seqkit'], sep='\t', usecols=['file', 'num_seqs', 'sum_len', 'N50'])
    seqkit_df = seqkit_df.rename({'file': 'binId'}, axis=1)
    seqkit_df['binId'] = seqkit_df['binId'].str.replace('\.fa', '', regex=True)
    is_sub = seqkit_df['binId'].str.contains('_sub', regex=False).rename('is_sub')
    seqkit_df['is_sub'] = is_sub
    seqkit_df['binId'] = seqkit_df['binId'].str.replace('_sub', '')

    checkm_df = pd.read_csv(args['checkm'], sep='\t', usecols=['Bin Id', 'Marker lineage', 'Completeness', 'Contamination'])
    checkm_df = checkm_df.rename({'Bin Id': 'binId', 'Marker lineage': 'checkm_lineage'}, axis=1)
    checkm_df['binId'] = checkm_df['binId'].str.replace('_sub', '')

    bin_annotation_df = pd.merge(left=gtdbk_df, right=seqkit_df, left_on='binId', right_on='binId', how='outer')
    bin_annotation_df = bin_annotation_df.merge(right=checkm_df, left_on='binId', right_on='binId')
    contig2bins_df = contig2bins_df.merge(right=bin_annotation_df, left_on='binId', right_on='binId', how='left')
    contig2bins_df = contig2bins_df.dropna(axis=0)
    contig2bins_df = contig2bins_df.sort_values(by=['is_sub'])
    contig2bins_df = contig2bins_df.drop_duplicates(subset=["contigId"], keep="first")
    contig2bins_df = contig2bins_df.loc[:, ['contigId', 'binId']]
    bin_annotation_df = bin_annotation_df.drop(labels=["is_sub"], axis=1)

    bin_annotation_df.to_csv(f"{args['outdir']}/bin_annotation.tsv", sep='\t', index=False)
    contig2bins_df.to_csv(f"{args['outdir']}/contigs2bins.tsv", sep='\t', index=False)

if __name__ == "__main__":
    main()