#!/usr/bin/env python3

import argparse
import csv
import os
import sys

def parse_args():
    parser = argparse.ArgumentParser(description="split contig into hq (>=90%) and lq (<90% or unevaluated).")
    parser.add_argument("-c", "--checkm", required=True, help="path to CheckM output TSV file.")
    parser.add_argument("--hq-dir", default="hq_bins", help="output directory for hq contigs.")
    parser.add_argument("--lq-dir", default="lq_bins", help="output directory for remaining contigs.")
    parser.add_argument("-t", "--threshold", type=float, default=90.0, help="completeness threshold.")
    parser.add_argument("contigs", nargs="+", help="fasta files corresponding to the contigs.")
    return parser.parse_args()

def main():
    args = parse_args()
    
    os.makedirs(args.hq_dir, exist_ok=True)
    os.makedirs(args.lq_dir, exist_ok=True)
        
    bin_file_map = {}
    for bin_path in args.contigs:
        basename = os.path.basename(bin_path)
        bin_id = os.path.splitext(basename)[0]
        bin_file_map[bin_id] = bin_path
        
    hq_bin_ids = set()
    
    with open(args.checkm, "r") as f:
        reader = csv.DictReader(f, delimiter="\t")
        
        if not reader.fieldnames:
            sys.exit("error: CheckM tsv file is empty or missing headers.")
            
        id_col = next((c for c in reader.fieldnames if c.lower() in ["bin id", "name", "bin"]), None)
        comp_col = next((c for c in reader.fieldnames if "completeness" in c.lower()), None)
        
        for row in reader:
            try:
                completeness = float(row[comp_col])
                if completeness >= args.threshold:
                    hq_bin_ids.add(row[id_col])
            except ValueError:
                continue 

    for bin_id, target_file in bin_file_map.items():
        outdir = args.hq_dir if bin_id in hq_bin_ids else args.lq_dir
        
        target_path = os.path.abspath(target_file)
        link_name = os.path.join(outdir, os.path.basename(target_file))
        
        if not os.path.exists(link_name):
            os.symlink(target_path, link_name)

if __name__ == "__main__":
    main()
