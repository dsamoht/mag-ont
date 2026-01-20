#!/usr/bin/env python
import argparse
import os
import sys

import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(description='Summarize MAG statistics from `mag-ont` outputs.')
    parser.add_argument('--bins', nargs='+', required=True, help='Path to dastool .fa bin files')
    parser.add_argument('--checkm', required=True, help='Path to checkm_qa.tsv')
    parser.add_argument('--coverm', required=True, help='Path to coverm_stats.tsv')
    parser.add_argument('--bac120', help='Path to gtdbtk.bac120.summary.tsv')
    parser.add_argument('--ar53', help='Path to gtdbtk.ar53.summary.tsv')
    parser.add_argument('--group', required=True, help='Group ID (e.g., group_1)')
    parser.add_argument('--output', default='mag_summary.csv', help='Output CSV file name')
    return parser.parse_args()

def main():
    args = parse_args()

    # 1. Map filenames to Bin IDs, write contig2bin.csv
    with open(f"{args.group}_contig2bin.csv", "w") as c2b:
        bin_data = []
        for bin_path in args.bins:
            with open(bin_path) as bin_in:
                for line in bin_in:
                    if line.startswith(">"):
                        c2b.write(f"{line.strip().lstrip('>')},{os.path.basename(bin_path)}\n")
            fname = os.path.basename(bin_path)
            bin_id_key = os.path.splitext(fname)[0]
            bin_data.append({'bin_filename': fname, 'merge_id': bin_id_key})

    df_bins = pd.DataFrame(bin_data)

    # 2. CheckM
    try:
        df_checkm = pd.read_csv(args.checkm, sep='\t')
        df_checkm.columns = [c.strip() for c in df_checkm.columns]
        df_checkm = df_checkm[['Bin Id', 'Completeness', 'Contamination', 'Strain heterogeneity']]
    except Exception as e:
        print(f"Error reading CheckM file: {e}")
        sys.exit(1)

    # 3. CoverM
    try:
        df_coverm = pd.read_csv(args.coverm, sep='\t')
        df_coverm.columns = [c.strip() for c in df_coverm.columns]
        df_coverm = df_coverm[df_coverm['Genome'] != 'unmapped']
    except Exception as e:
        print(f"Error reading CoverM file: {e}")
        sys.exit(1)

    # 4. GTDB-Tk
    gtdb_list = []
    for gtdb_file in [args.bac120, args.ar53]:
        if gtdb_file and os.path.exists(gtdb_file):
            try:
                temp_df = pd.read_csv(gtdb_file, sep='\t')
                gtdb_list.append(temp_df)
            except Exception as e:
                print(f"Warning: Could not read {gtdb_file}: {e}")

    if gtdb_list:
        df_gtdb_raw = pd.concat(gtdb_list, ignore_index=True)
        df_gtdb = df_gtdb_raw[['user_genome', 'classification', 'closest_placement_reference',
                               'closest_placement_ani', 'warnings']].copy()
    else:
        print("Error: No valid GTDB-Tk summary files provided.")
        sys.exit(1)

    final_df = pd.merge(df_bins, df_checkm, left_on='merge_id', right_on='Bin Id', how='left')
    final_df = pd.merge(final_df, df_gtdb, left_on='merge_id', right_on='user_genome', how='left')
    final_df = pd.merge(final_df, df_coverm, left_on='merge_id', right_on='Genome', how='left')

    final_df['group_id'] = args.group
    final_df = final_df.reset_index(drop=True)
    final_df['bin_id'] = [(f"bin_{x:03d}") for x in range(1, len(final_df) + 1)]

    ranks = ['domain', 'phylum', 'class', 'order', 'family', 'genus', 'species']

    def split_taxonomy(val):
        if pd.isna(val) or "Unclassified" in str(val):
            return pd.Series(['Unclassified'] * 7)
        # GTDB taxonomy strings use semicolon d__;p__;...
        parts = val.split(';')
        # Clean up prefix (e.g., 'd__' -> '')
        clean_parts = [p.split('__')[1] if '__' in p else p for p in parts]
        while len(clean_parts) < 7:
            clean_parts.append('Unclassified')
        return pd.Series(clean_parts)

    final_df[ranks] = final_df['classification'].apply(split_taxonomy)

    # Column Selection
    coverm_cols = [c for c in df_coverm.columns if c != 'Genome']
    base_cols = [
        'bin_id', 'group_id', 'bin_filename', 'Completeness', 'Contamination',
        'Strain heterogeneity', 'domain', 'phylum', 'class', 'order', 'family',
        'genus', 'species', 'closest_placement_reference', 'closest_placement_ani', 'warnings'
    ]

    final_df = final_df[base_cols + coverm_cols]
    final_df.columns = [c.lower().replace(' ', '_') for c in final_df.columns]

    final_df.to_csv(args.output, index=False)
    print(f"Successfully created summary for {args.group} at {args.output}")

if __name__ == "__main__":
    main()
