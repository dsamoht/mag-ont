#!/usr/bin/env python3
"""
Sample a fasta file with a corresponding file of headers.

usage:
python fasta_sampler.py [FASTA] [HEADERS] > [SAMPLED_FASTA]

output:
[SAMPLED_FASTA] : fasta file containing sequences in [HEADERS]
"""

import sys

def main():

    id_to_seq = {}

    with open(sys.argv[1], "r", encoding="utf-8") as fasta_file:
        for line in fasta_file:
            if line.startswith(">"):
                current_id = line.strip()
                id_to_seq[current_id] = ""
            else:
                id_to_seq[current_id] += line.strip()

    with open(sys.argv[2], "r", encoding="utf-8") as header_file:
        for line in header_file:
            line = line.strip()
            if not line.startswith(">"):
                line = ">" + line
            try:
                fasta = f"{line}\n{id_to_seq[line]}"
                print(fasta)
            except KeyError:
                print("Identifier Error: ", end="")
                print(f""""{line}" is not in the list of headers""")
                sys.exit()

if __name__ == "__main__":
    main()