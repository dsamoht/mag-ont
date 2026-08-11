#!/usr/bin/env python3

import argparse
import textwrap
import os

def parse_fasta(file_path):
    """generator to yield (header, sequence) from a fasta file."""
    if not os.path.exists(file_path):
        return
        
    header = None
    seq = []
    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith(">"):
                if header:
                    yield header, "".join(seq)
                header = line[1:]
                seq = []
            else:
                seq.append(line)
        if header:
            yield header, "".join(seq)

def load_mapping(mapping_file):
    """load the mapping tsv into a dictionary."""
    mapping = {}
    with open(mapping_file, 'r') as f:
        for line in f:
            parts = line.rstrip('\n').split('\t', 1)
            if len(parts) == 2:
                safe_id, full_name = parts
                mapping[safe_id] = full_name
    return mapping

def main():
    parser = argparse.ArgumentParser(description="Concatenate FASTA files and restore original headers.")
    parser.add_argument('-s', '--small', required=True, help="Small contigs FASTA file")
    parser.add_argument('-n', '--nonhq', nargs='*', default=[], help="Non-HQ contigs FASTA file(s)")
    parser.add_argument('-m', '--mapping', required=True, help="Contig mapping TSV file")
    parser.add_argument('-o', '--output', required=True, help="Output concatenated FASTA file")
    parser.add_argument('-w', '--wrap', type=int, default=60, help="Line wrap length for sequences (default: 60)")
    
    args = parser.parse_args()

    mapping = load_mapping(args.mapping)

    input_files = [args.small] + args.nonhq
    
    with open(args.output, 'w') as out_f:
        for fasta_file in input_files:
            for header, seq in parse_fasta(fasta_file):
                safe_id = header.split()[0]
                
                original_header = mapping.get(safe_id, header)
                
                out_f.write(f">{original_header}\n")
                
                wrapped_seq = textwrap.fill(seq, width=args.wrap)
                out_f.write(f"{wrapped_seq}\n")

if __name__ == "__main__":
    main()