"""Tests of the helper scripts in bin/, run the way the modules call them.

    pip install pandas==2.2.3 pytest
    pytest tests/bin
"""

import csv
import subprocess
import sys
from pathlib import Path

import pytest

BIN = Path(__file__).resolve().parents[2] / "bin"


def run(script, *args, cwd):
    return subprocess.run(
        [sys.executable, str(BIN / script), *map(str, args)],
        cwd=cwd, capture_output=True, text=True,
    )


def write(path, text):
    path.write_text(text)
    return path


def read_tsv(path):
    with open(path) as f:
        return list(csv.DictReader(f, delimiter="\t"))


def read_csv(path):
    with open(path) as f:
        return list(csv.DictReader(f))


# ---------------------------------------------------------------- normalize_coverm_genome

def test_genome_columns_are_matched_by_exact_sample_name(tmp_path):
    # "S10 Mean" contains "S1": it must still be normalized with the depth of S10
    write(tmp_path / "cov.tsv",
          "Genome\tS1 Mean\tS1 Trimmed Mean\tS10 Mean\tS10 Trimmed Mean\n"
          "bin1\t2\t2\t2\t2\n")
    write(tmp_path / "S1.aligned_bases.tsv", "S1\t1000000\n")
    write(tmp_path / "S10.aligned_bases.tsv", "S10\t4000000\n")

    result = run("normalize_coverm_genome.py",
                 "-i", "cov.tsv", "-d", "S10.aligned_bases.tsv", "S1.aligned_bases.tsv",
                 "-o", "out.tsv", cwd=tmp_path)
    assert result.returncode == 0, result.stderr

    row = read_tsv(tmp_path / "out.tsv")[0]
    assert float(row["S1 Mean_norm_per_bp"]) == pytest.approx(2.0)
    assert float(row["S10 Mean_norm_per_bp"]) == pytest.approx(0.5)
    assert float(row["S10 Trimmed Mean_norm_per_bp"]) == pytest.approx(0.5)


def test_genome_zero_depth_gives_zero(tmp_path):
    write(tmp_path / "cov.tsv", "Genome\tS1 Mean\nbin1\t3\n")
    write(tmp_path / "S1.aligned_bases.tsv", "S1\t0\n")

    result = run("normalize_coverm_genome.py",
                 "-i", "cov.tsv", "-d", "S1.aligned_bases.tsv", "-o", "out.tsv", cwd=tmp_path)
    assert result.returncode == 0, result.stderr
    assert float(read_tsv(tmp_path / "out.tsv")[0]["S1 Mean_norm_per_bp"]) == 0


# ---------------------------------------------------------------- normalize_coverm_contig

def test_contig_normalization_keeps_dotted_sample_ids(tmp_path):
    write(tmp_path / "cov.tsv",
          "Contig\tS1.rep2 Mean\tS1.rep2 Trimmed Mean\n"
          "c1\t4\t3\n"
          "c2\t1\t1\n")
    write(tmp_path / "genes.gff",
          "##gff-version 3\n"
          "# Sequence Data: seqnum=1\n"
          "c1\tpyrodigal\tCDS\t1\t90\t.\t+\t0\tID=c1_1;partial=00\n"
          "c1\tpyrodigal\tCDS\t100\t190\t.\t-\t0\tID=c1_2;partial=00\n"
          "c2\tpyrodigal\tCDS\t1\t90\t.\t+\t0\tID=c2_1;partial=00\n")
    write(tmp_path / "S1.rep2.aligned_bases.tsv", "S1.rep2\t2000000\n")

    result = run("normalize_coverm_contig.py",
                 "-i", "cov.tsv", "-g", "genes.gff", "-d", "S1.rep2.aligned_bases.tsv",
                 "-o", "out.tsv", cwd=tmp_path)
    assert result.returncode == 0, result.stderr

    rows = {row["Gene"]: row for row in read_tsv(tmp_path / "out.tsv")}
    assert set(rows) == {"c1_1", "c1_2", "c2_1"}
    assert rows["c1_2"]["Contig"] == "c1"
    assert float(rows["c1_1"]["S1.rep2_Mean_norm"]) == pytest.approx(2.0)
    assert float(rows["c1_1"]["S1.rep2_Trimmed_Mean_norm"]) == pytest.approx(1.5)
    assert float(rows["c2_1"]["S1.rep2_Mean_norm"]) == pytest.approx(0.5)


# -------------------------------------------------------------------------- filter_hq_sc

def test_filter_hq_sc_splits_on_completeness_and_copies(tmp_path):
    for contig in ("a", "b", "c"):
        write(tmp_path / f"{contig}.fa", f">{contig}\nACGT\n")
    write(tmp_path / "quality_report.tsv",
          "Name\tCompleteness\tContamination\n"
          "a\t95.0\t1.0\n"
          "b\t50.0\t1.0\n"
          "c\tNone\t1.0\n")

    result = run("filter_hq_sc.py", "-c", "quality_report.tsv", "--hq-dir", "hq",
                 "--lq-dir", "lq", "-t", "90", "a.fa", "b.fa", "c.fa", cwd=tmp_path)
    assert result.returncode == 0, result.stderr

    assert sorted(p.name for p in (tmp_path / "hq").iterdir()) == ["a.fa"]
    assert sorted(p.name for p in (tmp_path / "lq").iterdir()) == ["b.fa", "c.fa"]
    assert not (tmp_path / "hq" / "a.fa").is_symlink()
    assert (tmp_path / "hq" / "a.fa").read_text() == ">a\nACGT\n"


def test_filter_hq_sc_fails_without_expected_columns(tmp_path):
    write(tmp_path / "a.fa", ">a\nACGT\n")
    write(tmp_path / "quality_report.tsv", "Genome\tScore\na\t95\n")

    result = run("filter_hq_sc.py", "-c", "quality_report.tsv", "a.fa", cwd=tmp_path)
    assert result.returncode != 0
    assert "no name or completeness column" in result.stderr


# ------------------------------------------------------------------------ concat_contigs

def test_concat_contigs_restores_original_headers(tmp_path):
    write(tmp_path / "small.fa", ">c1\nAAAA\n")
    write(tmp_path / "c2.fa", ">c2\nCCCC\n")
    write(tmp_path / "mapping.tsv", "c1\tc1 length=4 circular=no\nc2\tc2 length=4\n")

    result = run("concat_contigs.py", "--small", "small.fa", "--nonhq", "c2.fa",
                 "--mapping", "mapping.tsv", "--output", "out.fa", cwd=tmp_path)
    assert result.returncode == 0, result.stderr
    assert (tmp_path / "out.fa").read_text() == (
        ">c1 length=4 circular=no\nAAAA\n>c2 length=4\nCCCC\n"
    )


def test_concat_contigs_without_rejected_candidates(tmp_path):
    write(tmp_path / "small.fa", ">c1\nAAAA\n")
    write(tmp_path / "mapping.tsv", "c1\tc1\n")

    result = run("concat_contigs.py", "--small", "small.fa", "--nonhq",
                 "--mapping", "mapping.tsv", "--output", "out.fa", cwd=tmp_path)
    assert result.returncode == 0, result.stderr
    assert (tmp_path / "out.fa").read_text() == ">c1\nAAAA\n"


# -------------------------------------------------------------------- dastool_contig2bin

def test_dastool_contig2bin_names_bins_after_their_file(tmp_path):
    bins = tmp_path / "input_bins"
    bins.mkdir()
    write(bins / "metabat_bin.1.fa", ">c1 extra\nAC\n>c2\nGT\n")
    write(bins / "metabat_bin.2.fa", ">c3\nAC\n")
    write(bins / "notes.txt", "not a bin\n")

    result = run("dastool_contig2bin.py", "./input_bins", "metabat", cwd=tmp_path)
    assert result.returncode == 0, result.stderr
    assert (tmp_path / "metabat_contig2bin.tsv").read_text() == (
        "c1\tmetabat_bin.1\nc2\tmetabat_bin.1\nc3\tmetabat_bin.2\n"
    )


# --------------------------------------------------------------------------- mag_summary

CHECKM_HEADER = ("Name\tCompleteness\tContamination\tCompleteness_Model_Used\tTranslation_Table_Used\t"
                 "Coding_Density\tContig_N50\tAverage_Gene_Length\tGenome_Size\tGC_Content\t"
                 "Total_Coding_Sequences\tTotal_Contigs\tMax_Contig_Length\tAdditional_Notes\n")


def test_mag_summary_merges_quality_taxonomy_and_coverage(tmp_path):
    # bins arrive under their final names (RENAME_BINS), with the original name alongside
    write(tmp_path / "g1_bin_001.fa", ">contig_9\nACGT\n")
    write(tmp_path / "g1_bin_002.fa", ">c1\nACGT\n>c2\nACGT\n")
    write(tmp_path / "g1_bin_names.csv",
          "bin_id,original_bin\ng1_bin_001,contig_9.fa\ng1_bin_002,metabat_bin.1.fa\n")
    write(tmp_path / "quality_report.tsv",
          CHECKM_HEADER
          + "g1_bin_002\t97.5\t1.2\tm\t11\t0.9\t4\t300\t8\t0.5\t2\t2\t4\tNone\n"
          + "g1_bin_001\t91.0\t0.1\tm\t11\t0.9\t4\t300\t4\t0.5\t1\t1\t4\tlow coverage\n")
    write(tmp_path / "gtdbtk.bac120.summary.tsv",
          "user_genome\tclassification\tclosest_placement_reference\tclosest_placement_ani\twarnings\n"
          "g1_bin_002\td__Bacteria;p__Bacillota;c__Bacilli;o__;f__;g__;s__\tGCF_1\t97.1\tN/A\n")
    write(tmp_path / "coverm.tsv",
          "Genome\tS1 Mean\nunmapped\t0\ng1_bin_002\t12.5\ng1_bin_001\t3.0\n")

    result = run("mag_summary.py", "--bins", "g1_bin_002.fa", "g1_bin_001.fa",
                 "--bin-names", "g1_bin_names.csv",
                 "--checkm", "quality_report.tsv", "--bac120", "gtdbtk.bac120.summary.tsv",
                 "--coverm", "coverm.tsv", "--group", "g1", "--output", "g1_mag_summary.csv",
                 cwd=tmp_path)
    assert result.returncode == 0, result.stderr

    rows = {row["bin_id"]: row for row in read_csv(tmp_path / "g1_mag_summary.csv")}
    assert set(rows) == {"g1_bin_001", "g1_bin_002"}
    assert rows["g1_bin_001"]["original_bin"] == "contig_9.fa"
    assert rows["g1_bin_002"]["original_bin"] == "metabat_bin.1.fa"

    binned = rows["g1_bin_002"]
    assert float(binned["completeness"]) == 97.5
    assert binned["phylum"] == "Bacillota"
    assert binned["order"] == "Unclassified"
    assert float(binned["s1_mean"]) == 12.5
    assert binned["checkm_notes"] == ""

    single = rows["g1_bin_001"]
    assert single["domain"] == "Unclassified"
    assert single["checkm_notes"] == "low coverage"

    contig2bin = (tmp_path / "g1_contig2bin.csv").read_text().splitlines()
    assert contig2bin == ["g1_bin_001,contig_9", "g1_bin_002,c1", "g1_bin_002,c2"]


def test_mag_summary_without_checkm_and_gtdbtk(tmp_path):
    write(tmp_path / "g1_bin_001.fa", ">c1\nACGT\n")
    write(tmp_path / "g1_bin_names.csv", "bin_id,original_bin\ng1_bin_001,binA.fa\n")
    write(tmp_path / "coverm.tsv", "Genome\tS1 Mean\ng1_bin_001\t3\n")

    result = run("mag_summary.py", "--bins", "g1_bin_001.fa", "--bin-names", "g1_bin_names.csv",
                 "--coverm", "coverm.tsv", "--group", "g1", "--output", "g1_mag_summary.csv",
                 cwd=tmp_path)
    assert result.returncode == 0, result.stderr

    row = read_csv(tmp_path / "g1_mag_summary.csv")[0]
    assert row["completeness"] == ""
    assert row["species"] == "Unclassified"
    assert float(row["s1_mean"]) == 3


def test_mag_summary_fails_on_a_bin_without_a_name(tmp_path):
    write(tmp_path / "g1_bin_001.fa", ">c1\nACGT\n")
    write(tmp_path / "g1_bin_names.csv", "bin_id,original_bin\n")
    write(tmp_path / "coverm.tsv", "Genome\tS1 Mean\ng1_bin_001\t3\n")

    result = run("mag_summary.py", "--bins", "g1_bin_001.fa", "--bin-names", "g1_bin_names.csv",
                 "--coverm", "coverm.tsv", "--group", "g1", "--output", "g1_mag_summary.csv",
                 cwd=tmp_path)
    assert result.returncode != 0
    assert "g1_bin_001" in result.stderr
