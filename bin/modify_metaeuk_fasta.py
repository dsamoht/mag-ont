#!/usr/bin/env python
"""
Modify names of sequences in metaeuk fasta output

usage:
python modify_metaeuk_fasta.py -f [metaeuk fasta output, required] -o [output file path, required]

output:
<output> fasta file with renamed sequences names
"""
import argparse

def main():

    ap = argparse.ArgumentParser()
    ap.add_argument("-f", "--fastaMetaeuk", required=True)
    ap.add_argument("-o", "--output", required=True)
    args = vars(ap.parse_args())

    lines_list = []

    with open(args['fastaMetaeuk']) as infile:
        for line in infile:
            if line.startswith(">"):
                new_line = line.strip(">").rstrip()
                new_line = new_line.split('|')
                new_line = '>' + new_line[1] + '|' + new_line[2] + '_' + new_line[0] + '_' + new_line[3] + '\n'
                lines_list.append(new_line)
            else:
                lines_list.append(line)

    with open(args['output'], 'w') as file:
        file.writelines(lines_list)

if __name__ == "__main__":
    main()