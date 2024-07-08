#!/usr/bin/env python
"""
Write an annotation summary table (genes_annot_summary.tsv) with results from hmmer using Pfam and/or Kegg Ortholog profiles and/or Diammond blastp results.

usage:
python genes_annot_summmary.py -p [Pfam hmmer table, optional] -k [Kegg hmmer table, optional] -l [koList, required with -k] -d [Diammond blastp tsv output, optional]

output:
genes_annot_summary.tsv : best annotations for each genes by given inputs
"""
import pandas as pd
import os
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("-p", "--pfamPath", required=False)
ap.add_argument("-k", "--keggPath", required=False)
ap.add_argument("-l", "--koList", required=False)
ap.add_argument("-d", "--diamPath", required=False, nargs='+')
args = vars(ap.parse_args())

namesList = ["geneId", "accession_target",
                    "query_name", "accession_query",
                    "full_E_value", "full_score", "full_bias",
                    "dom_E_value", "dom_score", "dom_bias",
                    "exp", "reg", "clu", "ov", "env", "dom",
                    "rep", "inc"]


# Pfam
df_pfam = pd.DataFrame(columns=["geneId"], dtype=float)
if args['pfamPath'] != None:
    with open(args['pfamPath'], 'r') as fp:
        lines = len(fp.readlines())
    if lines > 13:
        df_pfam = pd.read_csv(args['pfamPath'], sep=" ", skiprows=3, skipfooter=10, header=None,
                        skipinitialspace=True, usecols=list(range(0, 18)),
                        names=namesList, na_values="-", engine="python")
        df_pfam = df_pfam.sort_values(by="full_E_value")
        df_pfam = df_pfam.drop_duplicates(subset=["geneId"], keep="first")
        df_pfam = df_pfam.iloc[:,[0,2,3,4]]
        df_pfam.columns = ["geneId", "pfam_name", "pfam_id", "pfam_E_value"]


# Kegg
df_kegg = pd.DataFrame(columns=["geneId"], dtype=float)
if args['keggPath'] != None:
    with open(args['keggPath'], 'r') as fp:
        lines = len(fp.readlines())
    if lines > 13:
        def swap_columns(df, col1, col2):
            col_list = list(df.columns)
            x, y = col_list.index(col1), col_list.index(col2)
            col_list[y], col_list[x] = col_list[x], col_list[y]
            df = df[col_list]
            return df

        ko_list = pd.read_csv(args['koList'], sep="\t")
        df_kegg = pd.read_csv(args['keggPath'], sep=" ", skiprows=3, skipfooter=10, header=None,
                        skipinitialspace=True, usecols=list(range(0, 18)),
                        na_values="-", engine="python")
        df_kegg = swap_columns(df_kegg, 2, 3)
        df_kegg.columns = namesList
        df_kegg = pd.merge(left=df_kegg, right=ko_list.iloc[:,[0, 11]], left_on="accession_query", right_on="knum")
        df_kegg.query_name = df_kegg.definition
        df_kegg = df_kegg.drop(["knum", "definition"], axis=1)
        df_kegg = df_kegg.sort_values(by="full_E_value")
        df_kegg = df_kegg.drop_duplicates(subset=["geneId"], keep="first")
        df_kegg = df_kegg.iloc[:,[0,2,3,4]]
        df_kegg.columns = ["geneId", "kegg_name", "kegg_id", "kegg_E_value"]
        


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
df_annot = pd.merge(left=df_pfam, right=df_kegg, left_on="geneId", right_on="geneId", how="outer")
df_annot = pd.merge(left=df_annot, right=df_diamond, left_on="geneId", right_on="geneId", how="outer")
df_annot.insert(0, 'geneId', df_annot.pop('geneId'))
df_annot.to_csv("genes_annot_summary.tsv", sep="\t", index=False)