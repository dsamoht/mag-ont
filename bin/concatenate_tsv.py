#!/usr/bin/env python
"""
Concatenate multiple tsv files

usage:
python concatenate_tsv.py -i [paths to tsv files, required] -o [output file path, required]

output:
Single tsv file
"""
import pandas as pd
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("-i", "--input", required=True, nargs='+')
ap.add_argument("-o", "--output", required=True)
args = vars(ap.parse_args())

df_list = []
for tsv in args['input']:
    df_list.append(pd.read_csv(tsv, sep='\t'))

df = pd.concat(df_list, ignore_index=True)
df.to_csv(args['output'], sep="\t", index=False)