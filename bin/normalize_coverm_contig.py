#!/usr/bin/env python3

import pandas as pd
import argparse

def read_aligned_bases(depth_files):
    """sample -> aligned bases, from the `<sample>\t<bases>` files written by the mappers."""
    sample_depths = {}
    for depth_file in depth_files:
        with open(depth_file) as f:
            for line in f:
                sample, bases = line.rstrip("\n").split("\t")
                sample_depths[sample] = int(bases)
                print(f" - {sample}: {bases} aligned bp")
    return sample_depths


def normalize_coverm_contig(coverm_tsv, depth_files, gff_file, output_file):
    # 1. Sequencing depth of each sample: aligned bases excluding unmapped reads, soft-clips
    # and secondary alignments, counted by `samtools stats` when the reads were mapped
    sample_depths = read_aligned_bases(depth_files)

    # 2. Parse GFF: Mapping Gene ID -> Parent Contig
    gff_mapping = []
    with open(gff_file, 'r') as f:
        for line in f:
            if line.startswith('#') or not line.strip():
                continue
            parts = line.split('\t')
            if parts[2] == 'CDS':
                contig = parts[0]
                attributes = parts[8]
                # Extract Gene ID (e.g., ID=contig_1_1)
                try:
                    gene_id = [x for x in attributes.split(';') if x.startswith('ID=')][0].split('=')[1]
                    gff_mapping.append({'Gene': gene_id, 'Contig': contig})
                except IndexError:
                    continue

    df_genes = pd.DataFrame(gff_mapping)

    # 3. Load and merge CoverM data
    df_coverm = pd.read_table(coverm_tsv)
    df_merged = pd.merge(df_genes, df_coverm, on='Contig', how='left')

    # 4. Apply normalization for each sample and metric (Mean and Trimmed Mean)
    metrics = ["Mean", "Trimmed Mean"]
    output_columns = ['Gene', 'Contig']

    for sample, total_depth in sample_depths.items():
        for metric in metrics:
            # Match CoverM source column name (e.g., "test1 Mean")
            source_col = f"{sample} {metric}"
            # Construct new normalized column name (e.g., "test1_Mean_norm")
            norm_col_name = f"{sample}_{metric.replace(' ', '_')}_norm"

            if source_col in df_merged.columns:
                if total_depth > 0:
                    # Formula: Coverage * (1,000,000 / Total Aligned Bases)
                    # Result: Average coverage per million aligned bases
                    df_merged[norm_col_name] = df_merged[source_col] * (1_000_000 / total_depth)
                else:
                    df_merged[norm_col_name] = 0
                output_columns.append(norm_col_name)

    # 5. Export final matrix
    df_merged[output_columns].to_csv(output_file, sep="\t", index=False)
    print(f"\nDone. Results written to: {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Normalize CoverM coverage metrics by sample depth.")
    parser.add_argument("-i", "--input", required=True, help="CoverM contig output TSV.")
    parser.add_argument("-g", "--gff", required=True, help="GFF3 annotation file.")
    parser.add_argument("-d", "--depths", required=True, nargs='+', help="Aligned bases file(s), one '<sample>\\t<bases>' line each.")
    parser.add_argument("-o", "--output", required=True, help="Output TSV file name.")

    args = parser.parse_args()
    normalize_coverm_contig(args.input, args.depths, args.gff, args.output)
