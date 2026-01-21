#!/usr/bin/env python3
import argparse
import os
import sys
from pathlib import Path
from typing import Dict, List

import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(
        description="Summarize MAG statistics and generate contig-to-bin mapping."
    )
    parser.add_argument(
        "--bins", nargs="+", required=True,
        help="Paths to bin FASTA files (e.g. DAS Tool output .fa/.fna/.fasta)"
    )
    parser.add_argument("--checkm", help="Path to checkm_qa.tsv")
    parser.add_argument("--coverm", help="Path to coverm_stats.tsv")
    parser.add_argument("--bac120", help="Path to gtdbtk.bac120.summary.tsv")
    parser.add_argument("--ar53", help="Path to gtdbtk.ar53.summary.tsv")
    parser.add_argument("--group", required=True, help="Group ID")
    parser.add_argument(
        "--output", default="mag_summary.csv",
        help="Output MAG summary CSV"
    )
    return parser.parse_args()


def iter_fasta_contigs(fasta_path: Path):
    """Yield contig IDs from a FASTA file."""
    with fasta_path.open() as fh:
        for line in fh:
            if line.startswith(">"):
                header = line[1:].strip()
                if not header:
                    continue
                yield header.split()[0]


def main():
    args = parse_args()

    # ------------------------------
    # Validate required inputs
    # ------------------------------
    if not args.bins:
        sys.exit("ERROR: No bin FASTA files provided.")

    for f in args.bins:
        if not os.path.isfile(f):
            sys.exit(f"ERROR: Bin file not found: {f}")

    group = args.group

    # ------------------------------
    # Assign deterministic bin IDs
    # ------------------------------
    bin_paths = sorted(Path(p) for p in args.bins)

    bin_id_map: Dict[str, str] = {}
    bin_rows: List[dict] = []

    for i, bin_path in enumerate(bin_paths, start=1):
        new_bin_id = f"{group}_bin_{i:03d}"
        stem = bin_path.stem

        bin_id_map[stem] = new_bin_id
        bin_rows.append({
            "bin_filename": bin_path.name,
            "merge_id": stem,
            "bin_id": new_bin_id
        })

    df_bins = pd.DataFrame(bin_rows)

    # ------------------------------
    # Write contig2bin mapping
    # ------------------------------
    contig2bin_path = f"{group}_contig2bin.csv"

    try:
        with open(contig2bin_path, "w") as c2b:
            for bin_path in bin_paths:
                stem = bin_path.stem
                new_bin_id = bin_id_map[stem]

                for contig in iter_fasta_contigs(bin_path):
                    c2b.write(f"{new_bin_id},{contig}\n")
    except Exception as e:
        sys.exit(f"ERROR writing contig2bin file: {e}")

    # ------------------------------
    # CheckM (optional)
    # ------------------------------
    checkm_cols = [
        "Bin Id",
        "Completeness",
        "Contamination",
        "Strain heterogeneity",
    ]

    if args.checkm and os.path.isfile(args.checkm):
        try:
            df_checkm = pd.read_csv(args.checkm, sep="\t")
            df_checkm.columns = df_checkm.columns.str.strip()

            missing = set(checkm_cols) - set(df_checkm.columns)
            if missing:
                raise ValueError(f"Missing CheckM columns: {missing}")

            df_checkm = df_checkm[checkm_cols]
        except Exception as e:
            print(f"WARNING: CheckM unreadable ({e}); filling NA", file=sys.stderr)
            df_checkm = pd.DataFrame(columns=checkm_cols)
    else:
        df_checkm = pd.DataFrame(columns=checkm_cols)

    # ------------------------------
    # CoverM (optional)
    # ------------------------------
    if args.coverm and os.path.isfile(args.coverm):
        try:
            df_coverm = pd.read_csv(args.coverm, sep="\t")
            df_coverm.columns = df_coverm.columns.str.strip()

            if "Genome" not in df_coverm.columns:
                raise ValueError("Missing Genome column")

            df_coverm = df_coverm[df_coverm["Genome"] != "unmapped"]
        except Exception as e:
            print(f"WARNING: CoverM unreadable ({e}); filling NA", file=sys.stderr)
            df_coverm = pd.DataFrame(columns=["Genome"])
    else:
        df_coverm = pd.DataFrame(columns=["Genome"])

    # ------------------------------
    # GTDB-Tk (optional)
    # ------------------------------
    gtdb_cols = [
        "user_genome",
        "classification",
        "closest_placement_reference",
        "closest_placement_ani",
        "warnings",
    ]

    gtdb_frames = []

    for gtdb_file in (args.bac120, args.ar53):
        if gtdb_file and os.path.isfile(gtdb_file):
            try:
                df = pd.read_csv(gtdb_file, sep="\t")
                df.columns = df.columns.str.strip()

                missing = set(gtdb_cols) - set(df.columns)
                if missing:
                    raise ValueError(f"Missing GTDB columns: {missing}")

                gtdb_frames.append(df[gtdb_cols])
            except Exception as e:
                print(f"WARNING: GTDB-Tk file skipped ({e})", file=sys.stderr)

    if gtdb_frames:
        df_gtdb = pd.concat(gtdb_frames, ignore_index=True)
    else:
        df_gtdb = pd.DataFrame(columns=gtdb_cols)

    # ------------------------------
    # Merge all tables
    # ------------------------------
    final_df = (
        df_bins
        .merge(df_checkm, left_on="merge_id", right_on="Bin Id", how="left")
        .merge(df_gtdb, left_on="merge_id", right_on="user_genome", how="left")
        .merge(df_coverm, left_on="merge_id", right_on="Genome", how="left")
    )

    final_df["group_id"] = group

    # ------------------------------
    # Taxonomy parsing (rank-aware)
    # ------------------------------
    ranks = ["domain", "phylum", "class", "order", "family", "genus", "species"]

    def split_taxonomy(val):
        if pd.isna(val):
            return pd.Series(["Unclassified"] * 7)

        raw_parts = val.split(";")
        cleaned = []

        for p in raw_parts:
            if "__" in p:
                tax = p.split("__", 1)[1]
            else:
                tax = p

            if not tax or tax == "Unclassified":
                cleaned.append("Unclassified")
            else:
                cleaned.append(tax)

        # pad missing lower ranks
        cleaned += ["Unclassified"] * (7 - len(cleaned))

        return pd.Series(cleaned[:7])

    final_df[ranks] = final_df["classification"].apply(split_taxonomy)

    # ------------------------------
    # Final formatting and output
    # ------------------------------
    coverm_cols = [c for c in df_coverm.columns if c != "Genome"]

    base_cols = [
        "bin_id",
        "group_id",
        "bin_filename",
        "Completeness",
        "Contamination",
        "Strain heterogeneity",
        *ranks,
        "closest_placement_reference",
        "closest_placement_ani",
        "warnings",
    ]

    final_df = final_df[base_cols + coverm_cols]
    final_df.columns = final_df.columns.str.lower().str.replace(" ", "_")

    final_df.to_csv(args.output, index=False)

    print(f"Successfully created summary for {group} at {args.output}")
    print(f"Contig-to-bin mapping written to {contig2bin_path}")


if __name__ == "__main__":
    main()
