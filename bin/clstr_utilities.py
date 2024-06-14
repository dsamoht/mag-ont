"""Utilities."""
from __future__ import annotations
from argparse import ArgumentParser
from pathlib import Path
import pickle
import pandas as pd
import polars as pl


class ClusterSeq:
    """
    Main class of clustering utilities.
    """
    def __init__(self, clstr: str | Path, fasta: str | Path, output_dir: str | Path) -> None:
        """
        An object containing:
        - DataFrame `seq_info_df` where columns are:
        `seq_id`: str, `sequence`: str, `cluster`: str, `source`: str, `representative`: boolean;
        - utility functions to filter `seq_info_df` and output files of different format.
        Parameters:
        -----------
        `clstr`: .clstr file (`CD-HIT` output);
        `fasta`: fasta file given as input to `CD-HIT`.
        """

        self.clstr_file = Path(clstr)
        self.clstr_base_name = self.clstr_file.name.rstrip(r".clstr")
        self.fasta_file = Path(fasta)
        Path(output_dir).mkdir(parents=True, exist_ok=True)
        self.output_dir = Path(output_dir)
        self._sequence_clstr_info_df()
        self._matrix_from_cdhit()

    def _sequence_clstr_info_df(self) -> None:
        """
        Build `seq_info_df`.
        """
        sequence_info = {}
        with open(self.fasta_file, "r", encoding="UTF-8") as fasta_input:
            for line in fasta_input:
                if line.startswith(">"):
                    current_name = line.strip().split()[0]
                    sequence_info[current_name] = [line.strip(), ""]
                else:
                    sequence_info[current_name][1] += line.strip()

        clstr_info = {}
        with open(self.clstr_file, "r", encoding="UTF-8") as clstr_input:
            index = -1
            for line in clstr_input:
                rep = False
                if line.startswith(">"):
                    current_clstr = f"cluster_{line.split()[1]}"
                else:
                    index += 1
                    if line.strip().endswith(r"*"):
                        rep = True
                    seq_name, seq = sequence_info[line.split()[2].rstrip(r"...")]
                    clstr_info[index] = seq_name, seq, seq_name.split("|")[0][1:], current_clstr, rep

        seq_info_pd_df = pd.DataFrame.from_dict(clstr_info, orient="index",
                                   columns=["seq_id", "seq", "source", "cluster", "representative"])

        self.seq_info_df = pl.from_pandas(seq_info_pd_df)
        del seq_info_pd_df
        with open(self.output_dir.joinpath("clusters_info_polars.pkl"), "wb") as f_output:
            pickle.dump(self.seq_info_df, f_output)


    def contiguity_network(self, file: str | Path) -> None:
        """
        Write a contiguity network to `file`, where nodes are clusters number
        and edges are contiguous genes.

        How to interpet:
        If clusters A and B are joined by 1 edge, it means that 1 gene from
        cluster A is contiguous to 1 gene from cluster B. A chain of clusters
        might represent a genomic region of interest
        (example: biosynthetic gene clusters).

        Parameter:
        -----------
        `file`: path to output file
        """
        tmp_df = self.seq_info_df.filter(pl.col('source')=='SAMPLE')



    def clusters_to_fasta(self, clusters_list: str | Path) -> None:
        """
        Extract sequences from cluster(s) and throw them in file(s)
        named cluster_X.faa in `output_dir/fastas/`.

        Parameter:
        -----------
        `clusters_list`: path to a file containing one cluster id (ex: cluster_0) per line.
        """
        self.output_dir.joinpath("fastas/").mkdir(parents=True, exist_ok=True)
        fasta_dir = self.output_dir.joinpath("fastas/")
        with open(clusters_list, "r", encoding="UTF-8") as clstr_list:
            for clstr in clstr_list:
                cluster_name = clstr.strip()
                filtered_df = self.seq_info_df.filter(pl.col("cluster") == cluster_name)
                output_file_name = fasta_dir.joinpath(f"{cluster_name}.faa")
                with open(output_file_name, "w", encoding="UTF-8") as fasta_output:
                    filtered_df.apply(lambda row: fasta_output.write(f"{row[0]}\n{row[1]}\n"))

    def _matrix_from_cdhit(self) -> None:
        """
        Parse .clstr file (output from `CD-HIT`).
        - count number of hits per sample in each cluster;
        - write the .tsv output in `output_dir/tsv/`;
        - adapted from original script by @Pier-Luc Plante.
        """

        self.output_dir.joinpath("tsv/").mkdir(parents=True, exist_ok=True)
        tsv_dir = self.output_dir.joinpath("tsv/")
        output_file = tsv_dir.joinpath(f"{self.clstr_base_name}.tsv")

        grouped_counts = self.seq_info_df.group_by(["cluster", "source"]).agg(pl.len().alias("count"))
        matrix = grouped_counts.pivot(values='count', index='cluster', columns='source').fill_null(0)
        matrix.write_csv(output_file)


    def featurecounts_matrix_from_cdhit(self, featurecounts_table: str | Path) -> None:
        """

        """
        featurecounts_df = pl.read_csv(featurecounts_table, separator='\t')
        seq_clust_df = self.seq_info_df
        seq_clust_df = seq_clust_df.with_columns(seq_clust_df['seq_id'].str.extract(r"^>(\S*)", group_index=1).alias('seq_id'))
        df_join = seq_clust_df.join(featurecounts_df, left_on="seq_id", right_on="contigId", how="left", coalesce=True)

        tsv_dir = self.output_dir.joinpath("tsv/")
        output_file = tsv_dir.joinpath(f"{self.clstr_base_name}_abundance.tsv")
        cluster_counts = df_join.pivot(index="cluster", columns="source", values="Abundance", aggregate_function="sum")
        cluster_counts.write_csv(output_file)


    def _clstr_rep_fasta(self) -> None:
        """
        Write all the clstr representatives to a fasta file.
        """
        raise NotImplementedError



if __name__ == '__main__':


    parser = ArgumentParser(description='''`clusterseq` is a command-line tool to extract
                                            information about a clustering experiment made
                                            with software `CD-HIT`.''')
    parser.add_argument('-c', '--clstr', help='''.clstr file (CD-HIT's output)''')
    parser.add_argument('-f', '--fasta', help='''source .faa file (CD-HIT's input)''')
    parser.add_argument('-o', '--output', help='''output directory''')
    parser.add_argument('-e', '--extract', help='''file containing clusters of interest
                                                   (1 per line) -> output: 1 fasta file
                                                   per cluster.''')
    parser.add_argument('-a', '--abundance', help='''featurecounts abundance table''')

    args = parser.parse_args()


    exp = ClusterSeq(args.clstr, args.fasta, args.output)
    if args.extract:
        exp.clusters_to_fasta(args.extract)
    if args.abundance:
        exp.featurecounts_matrix_from_cdhit(args.abundance)
