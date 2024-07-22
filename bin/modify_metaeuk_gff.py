#!/usr/bin/env python
"""
usage:

./modify_gff_from_metaeuk.py --MetaEuk_fas_output [output from metaeuk predict, required] --gff3_output_filename [desired output filename, default is input filename replacing suffix fas with gff3]
"""
import argparse


# Initiate the parser
parser = argparse.ArgumentParser()

# Add long and short argument
parser.add_argument("--MetaEuk_fas_output", "-f", help="The MetaEuk fas output produced from MetaEuk easy-predict")
parser.add_argument("--gff3_output_filename", "-g", help="The output filename for the produced gff3 file. Default is the input filename with extension gff3",default='')

# Read arguments from the command line
args = parser.parse_args()

# store filenames
filename_infile=args.MetaEuk_fas_output
output_filename=args.gff3_output_filename

# Make output file
if output_filename == '':
    output_filename = filename_infile.replace("." + filename_infile.split(".")[-1], ".gff3")


initial_list = []

with open(filename_infile) as infile:
    for line in infile:
        if line.startswith(">"):
            initial_list.append(line.strip(">").rstrip())


with open(output_filename, 'w') as f:
    if len(initial_list) != 0:
        f.write("##gff_version 3\n")

    for entry in initial_list:
        entry_list = (entry.split("|",8))

        entry_seqid = entry_list[1]
        entry_source = 'metaEuk_AndyGff'
        entry_score = entry_list[3]
        entry_strand = entry_list[2]
        entry_numExons = entry_list[5]

        adjust_on_strand = 0
        if entry_strand == '+':
            adjust_on_strand = int(1)
    
            gene = [entry_seqid,entry_source,'gene',(int(entry_list[6]) +adjust_on_strand) ,(int(entry_list[7]) +adjust_on_strand),\
                entry_score,entry_strand,'.','ID=' + entry_list[0]]
            for item in gene:
                f.write(str(item) + '\t')
            f.write('\n')

            mRNA = [entry_seqid,entry_source,'mRNA',(int(entry_list[6])+adjust_on_strand), (int(entry_list[7]) + +adjust_on_strand),\
                entry_score,entry_strand,'.','ID=' + entry_list[0] + '_mRNA;Parent='+entry_list[0]]
            for item in mRNA:
                f.write(str(item) + '\t')
            f.write('\n')

            exon_cds_segments = entry_list[-1].split('|')
            exon_segments = []
            for gffLines in range(int(entry_numExons)):
                exon_segments = []
                exon_start=int(exon_cds_segments[gffLines].split('[')[0]) + +adjust_on_strand
                exon_end=int(exon_cds_segments[gffLines].split(':')[1].split('[')[0]) + adjust_on_strand
                exon_segments = [entry_seqid,entry_source,'exon',exon_start,exon_end,entry_score,entry_strand,'.',\
                    'ID=' + entry_list[0] + '_exonA;Parent=' + entry_list[0] + '_mRNA']
                for item in exon_segments:
                    f.write(str(item) + '\t')
                f.write('\n')

                cds_segments = []
                cds_start=int(exon_cds_segments[gffLines].split(']')[0].split('[')[1]) + +adjust_on_strand
                cds_end=int(exon_cds_segments[gffLines].split(':')[1].split('[')[1].strip(']')) + adjust_on_strand
                cds_segments = [entry_seqid,entry_source,'CDS',cds_start,cds_end,entry_score,entry_strand,'.',\
                    'ID=' + entry_list[0] + '_cdsB;Parent=' + entry_list[0] + '_mRNA']
                for item in cds_segments:
                    f.write(str(item) + '\t')
                f.write('\n')

        elif entry_strand == '-':
            adjust_on_strand = int(1)
    
            gene = [entry_seqid,entry_source,'gene',(int(entry_list[6]) + adjust_on_strand),(int(entry_list[7]) +adjust_on_strand),\
                entry_score,entry_strand,'.','ID=' + entry_list[0]]
            for item in gene:
                f.write(str(item) + '\t')
            f.write('\n')

            mRNA = [entry_seqid,entry_source,'mRNA',(int(entry_list[6])+adjust_on_strand), (int(entry_list[7]) +adjust_on_strand),\
                entry_score,entry_strand,'.','ID=' + entry_list[0] + '_mRNA;Parent='+entry_list[0]]
            for item in mRNA:
                f.write(str(item) + '\t')
            f.write('\n')

            
        
            exon_cds_segments = entry_list[-1].split('|')
            exon_segments = []
            for gffLines in range(int(entry_numExons)):
                exon_segments = []
                exon_end=int(exon_cds_segments[gffLines].split('[')[0]) + +adjust_on_strand
                exon_start=int(exon_cds_segments[gffLines].split(':')[1].split('[')[0]) + adjust_on_strand
                exon_segments = [entry_seqid,entry_source,'exon',exon_start,exon_end,entry_score,entry_strand,'.',\
                    'ID=' + entry_list[0] + '_exonA;Parent=' + entry_list[0] + '_mRNA']
                for item in exon_segments:
                    f.write(str(item) + '\t')
                f.write('\n')

                cds_segments = []
                cds_end=int(exon_cds_segments[gffLines].split(']')[0].split('[')[1]) + +adjust_on_strand
                cds_start=int(exon_cds_segments[gffLines].split(':')[1].split('[')[1].strip(']')) + adjust_on_strand
                cds_segments = [entry_seqid,entry_source,'CDS',cds_start,cds_end,entry_score,entry_strand,'.',\
                    'ID=' + entry_list[0] + '_cdsB;Parent=' + entry_list[0] + '_mRNA']
                for item in cds_segments:
                    f.write(str(item) + '\t')
                f.write('\n')

        else:
            print('No strand on this header? Major error')
