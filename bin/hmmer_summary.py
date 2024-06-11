#!/usr/bin/env python
"""
usage:

Write a contig annotation table (contig_annotation.tsv) with results from Pfam and/or Kegg Ortholog.
"""
import pandas as pd
import os.path
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("-p", "--pfamPath", required=False)
ap.add_argument("-k", "--keggPath", required=False)
ap.add_argument("-l", "--koList", required=False)
ap.add_argument("-d", "--diamPath", required=False)
args = vars(ap.parse_args())

namesList = ["contigId", "accession_target", "tlen",
                    "query_name", "accession_query", "qlen",
                    "full_E_value", "full_score", "full_bias",
                    "dom_#", "dom_of", "dom_c_Evalue",
                    "dom_i_Evalue", "dom_score", "dom_bias",
                    "hmm_coord_from", "hmm_coord_to",
                    "ali_coord_from", "ali_coord_to",
                    "env_coord_from", "env_coord_to", "acc"]


# Pfam
if args['pfamPath'] != None:
    with open(args['pfamPath'], 'r') as fp:
        lines = len(fp.readlines())
    if lines <= 13:
        df_pfam = pd.DataFrame(columns=["contigId", "genPred_len", "pfam_name", "pfam_id", "pfam_qlen", "pfam_E_value"])
    else:
        df_pfam = pd.read_csv(args['pfamPath'], sep=" ", skiprows=3, skipfooter=10, header=None,
                        skipinitialspace=True, usecols=list(range(0, 22)),
                        names=namesList, na_values="-", engine="python")
        df_pfam = df_pfam.sort_values(by="full_E_value")
        df_pfam = df_pfam.drop_duplicates(subset=["contigId"], keep="first")
        df_pfam = df_pfam.iloc[:,[0,2,3,4,5,6]]
        df_pfam.columns = ["contigId", "genPred_len", "pfam_name", "pfam_id", "pfam_qlen", "pfam_E_value"]
else:
    df_pfam = pd.DataFrame(columns=["contigId", "genPred_len", "pfam_name", "pfam_id", "pfam_qlen", "pfam_E_value"])


# Kegg
if args['keggPath'] != None:
    def swap_columns(df, col1, col2):
        col_list = list(df.columns)
        x, y = col_list.index(col1), col_list.index(col2)
        col_list[y], col_list[x] = col_list[x], col_list[y]
        df = df[col_list]
        return df

    ko_list = pd.read_csv(args['koList'], sep="\t")
    with open(args['keggPath'], 'r') as fp:
        lines = len(fp.readlines())
    if lines <= 13:
        df_kegg = pd.DataFrame(columns=["contigId", "genPred_len", "pfam_name", "pfam_id", "pfam_qlen", "pfam_E_value"])
    else:
        df_kegg = pd.read_csv(args['keggPath'], sep=" ", skiprows=3, skipfooter=10, header=None,
                        skipinitialspace=True, usecols=list(range(0, 22)),
                        na_values="-", engine="python")
        df_kegg = swap_columns(df_kegg, 3, 4)
        df_kegg.columns = namesList
        df_kegg = pd.merge(left=df_kegg, right=ko_list.iloc[:,[0, 11]], left_on="accession_query", right_on="knum")
        df_kegg.query_name = df_kegg.definition
        df_kegg = df_kegg.drop(["knum", "definition"], axis=1)
        df_kegg = df_kegg.sort_values(by="full_E_value")
        df_kegg = df_kegg.drop_duplicates(subset=["contigId"], keep="first")
        df_kegg = df_kegg.iloc[:,[0,2,3,4,5,6]]
        df_kegg.columns = ["contigId", "genPred_len", "kegg_name", "kegg_id", "kegg_qlen", "kegg_E_value"]
else:
    df_kegg = pd.DataFrame(columns=["contigId", "genPred_len", "kegg_name", "kegg_id", "kegg_qlen", "kegg_E_value"])


# Diammond
if args['diamPath'] != None:
    df_diammond = pd.read_csv(args['diamPath'], sep="\t",
                            usecols=[0, 1, 2, 3, 10], header=None)
    df_diammond.columns = ["contigId", "diam_name", "diam_seq_identity", "diam_aln_len", "diam_E_value"]
    df_diammond = df_diammond.sort_values(by="diam_E_value")
    df_diammond = df_diammond.drop_duplicates(subset=["contigId"], keep="first")
else:
    df_diammond = pd.DataFrame(columns=["contigId", "diam_name", "diam_seq_identity", "diam_aln_len", "diam_E_value"])


# Merge
df_annot = pd.merge(left=df_pfam, right=df_kegg, left_on="contigId", right_on="contigId", how="outer")
df_annot = pd.merge(left=df_annot, right=df_diammond, left_on="contigId", right_on="contigId", how="outer")
df_annot.loc[(df_annot['genPred_len_x'].isna()) & (df_annot['genPred_len_y'].notna()), 'genPred_len_x'] = df_annot['genPred_len_y'][(df_annot['genPred_len_x'].isna()) & (df_annot['genPred_len_y'].notna())]
df_annot = df_annot.rename(columns={"genPred_len_x":"genPred_len"})
df_annot = df_annot.drop("genPred_len_y", axis=1)
df_annot.to_csv("contig_annotation.tsv", sep="\t")