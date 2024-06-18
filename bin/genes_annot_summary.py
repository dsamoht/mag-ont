#!/usr/bin/env python
"""
Write an annotation summary table (genes_annot_summary.tsv) with results from hmmer using Pfam and/or Kegg Ortholog profiles and/or Diammond blastp.

usage:
python genes_annot_summmary.py -p [Pfam hmmer dom-table, optional] -k [Kegg hmmer dom-table, optional] -l [koList, required with -k] -d [Diammond blastp tsv output, optional]

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
ap.add_argument("-d", "--diamPath", required=False)
args = vars(ap.parse_args())

namesList = ["geneId", "accession_target", "tlen",
                    "query_name", "accession_query", "qlen",
                    "full_E_value", "full_score", "full_bias",
                    "dom_#", "dom_of", "dom_c_Evalue",
                    "dom_i_Evalue", "dom_score", "dom_bias",
                    "hmm_coord_from", "hmm_coord_to",
                    "ali_coord_from", "ali_coord_to",
                    "env_coord_from", "env_coord_to", "acc"]


# Pfam
df_pfam = pd.DataFrame(columns=["geneId", "genPred_len", "pfam_name", "pfam_id", "pfam_qlen", "pfam_E_value"], dtype=float)
if args['pfamPath'] != None:
    with open(args['pfamPath'], 'r') as fp:
        lines = len(fp.readlines())
    if lines > 13:
        df_pfam = pd.read_csv(args['pfamPath'], sep=" ", skiprows=3, skipfooter=10, header=None,
                        skipinitialspace=True, usecols=list(range(0, 22)),
                        names=namesList, na_values="-", engine="python")
        df_pfam = df_pfam.sort_values(by="full_E_value")
        df_pfam = df_pfam.drop_duplicates(subset=["geneId"], keep="first")
        df_pfam = df_pfam.iloc[:,[0,2,3,4,5,6]]
        df_pfam.columns = ["geneId", "genPred_len", "pfam_name", "pfam_id", "pfam_qlen", "pfam_E_value"]


# Kegg
df_kegg = pd.DataFrame(columns=["geneId", "genPred_len", "kegg_name", "kegg_id", "kegg_qlen", "kegg_E_value"], dtype=float)
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
                        skipinitialspace=True, usecols=list(range(0, 22)),
                        na_values="-", engine="python")
        df_kegg = swap_columns(df_kegg, 3, 4)
        df_kegg.columns = namesList
        df_kegg = pd.merge(left=df_kegg, right=ko_list.iloc[:,[0, 11]], left_on="accession_query", right_on="knum")
        df_kegg.query_name = df_kegg.definition
        df_kegg = df_kegg.drop(["knum", "definition"], axis=1)
        df_kegg = df_kegg.sort_values(by="full_E_value")
        df_kegg = df_kegg.drop_duplicates(subset=["geneId"], keep="first")
        df_kegg = df_kegg.iloc[:,[0,2,3,4,5,6]]
        df_kegg.columns = ["geneId", "genPred_len", "kegg_name", "kegg_id", "kegg_qlen", "kegg_E_value"]
        


# Diammond
df_diammond = pd.DataFrame(columns=["geneId", "diam_name", "diam_seq_identity", "diam_aln_len", "diam_E_value"], dtype=float)
if args['diamPath'] != None:
    if os.stat(args['diamPath']).st_size != 0:
        df_diammond = pd.read_csv(args['diamPath'], sep="\t",
                                usecols=[0, 1, 2, 3, 10], header=None)
        df_diammond.columns = ["geneId", "diam_name", "diam_seq_identity", "diam_aln_len", "diam_E_value"]
        df_diammond = df_diammond.sort_values(by="diam_E_value")
        df_diammond = df_diammond.drop_duplicates(subset=["geneId"], keep="first")


# Merge
df_annot = pd.merge(left=df_pfam, right=df_kegg, left_on="geneId", right_on="geneId", how="outer")
df_annot = pd.merge(left=df_annot, right=df_diammond, left_on="geneId", right_on="geneId", how="outer")
df_annot.insert(0, 'geneId', df_annot.pop('geneId'))
df_annot.loc[(df_annot['genPred_len_x'].isna()) & (df_annot['genPred_len_y'].notna()), 'genPred_len_x'] = df_annot['genPred_len_y'][(df_annot['genPred_len_x'].isna()) & (df_annot['genPred_len_y'].notna())]
df_annot = df_annot.rename(columns={"genPred_len_x":"genPred_len"})
df_annot = df_annot.drop("genPred_len_y", axis=1)
df_annot.to_csv("genes_annot_summary.tsv", sep="\t", index=False)