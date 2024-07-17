#!/usr/bin/env python
"""
Write an annotation summary table (genes_annot_summary.tsv) with results from hmmer hmmsearch and/or Diammond blastp results.

usage:
python genes_annot_summmary.py -t [hmmer tables, optional] -l [koList, used if hmmsearch was made on Kegg profiles, optional] -d [Diammond blastp tsv output, optional]

output:
genes_annot_summary.tsv : best annotations for each genes by given inputs
"""
import pandas as pd
import os
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("-t", "--hmmerTable", required=False, nargs='+')
ap.add_argument("-l", "--koList", required=False)
ap.add_argument("-d", "--diamPath", required=False, nargs='+')
args = vars(ap.parse_args())

namesList = ["geneId", "accession_target",
                    "query_name", "accession_query",
                    "full_E_value", "full_score", "full_bias",
                    "dom_E_value", "dom_score", "dom_bias",
                    "exp", "reg", "clu", "ov", "env", "dom",
                    "rep", "inc"]


# Hmmer
df_hmmer = pd.DataFrame(columns=["geneId"], dtype=float)
if args['hmmerTable'] != None:
    for i in args['hmmerTable']:
        with open(i, 'r') as file:
            lines = len(file.readlines())
        if lines > 13:
            df_table = pd.read_csv(i, sep=" ", skiprows=3, skipfooter=10, header=None,
                            skipinitialspace=True, usecols=list(range(0, 18)),
                            na_values="-", engine="python")
            if df_table[2].str.fullmatch(r'K[0-9]{5}').all() and df_table[3].isna().all():
                def swap_columns(df, col1, col2):
                    col_list = list(df.columns)
                    x, y = col_list.index(col1), col_list.index(col2)
                    col_list[y], col_list[x] = col_list[x], col_list[y]
                    df = df[col_list]
                    return df
                df_table = swap_columns(df_table, 2, 3)
                if args['koList'] != None:
                    ko_list = pd.read_csv(args['koList'], sep="\t")
                    df_table = pd.merge(left=df_table, right=ko_list.iloc[:,[0, 11]], left_on=2, right_on="knum")
                    df_table.insert(2, 'name', df_table.pop('definition'))
                    df_table = df_table.drop([3, "knum"], axis=1)
            df_table = df_table.iloc[:,[0,2,3,4]]
            table_name = i.split(sep='hmmer_table_')[-1].split(sep='.txt')[0]
            df_table.columns = ["geneId", f"{table_name}_name", f"{table_name}_id", f"{table_name}_E_value"]
            df_table = df_table.sort_values(by=f"{table_name}_E_value")
            df_table = df_table.drop_duplicates(subset=["geneId"], keep="first")
            df_hmmer = pd.merge(left=df_hmmer, right=df_table, left_on="geneId", right_on="geneId", how="outer")


# Diamond
df_diamond = pd.DataFrame(columns=["geneId"], dtype=float)
if args['diamPath'] != None:
    for i in args['diamPath']:
        if os.stat(i).st_size != 0:
            df_db = pd.read_csv(i, sep="\t",
                                     usecols=[0, 1, 2, 3, 10], header=None)
            db_name = i.split(sep='/')[-1].split(sep='.matches.tsv')[0]
            df_db.columns = ["geneId", f"{db_name}_name", f"{db_name}_seq_identity", f"{db_name}_aln_len", f"{db_name}_E_value"]
            df_db = df_db.sort_values(by=f"{db_name}_E_value")
            df_db = df_db.drop_duplicates(subset=["geneId"], keep="first")
            df_diamond = pd.merge(left=df_diamond, right=df_db, left_on="geneId", right_on="geneId", how="outer")


# Merge
df_annot = pd.merge(left=df_hmmer, right=df_diamond, left_on="geneId", right_on="geneId", how="outer")
df_annot.to_csv("genes_annot_summary.tsv", sep="\t", index=False)