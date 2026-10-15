#!usr/bin/env nextflow

include { BWA_INDEX               } from '../../modules/local/bwa/index'
include { BWA_MEM                 } from '../../modules/local/bwa/mem'
include { CHECKM                  } from '../../modules/local/checkm'
include { COMEBIN                 } from '../../modules/local/comebin'
include { COVERM_CONTIG           } from '../../modules/local/coverm/contig'
include { COVERM_GENOME           } from '../../modules/local/coverm/genome'
include { NORMALIZE_COVERM_CONTIG } from '../../modules/local/coverm/normalize/contig'
include { NORMALIZE_COVERM_GENOME } from '../../modules/local/coverm/normalize/genome'
include { DASTOOL                 } from '../../modules/local/dastool/dastool'
include { DASTOOL_CONTIG2BIN      } from '../../modules/local/dastool/dastool_contig2bin'
include { GTDBTK                  } from '../../modules/local/gtdbtk'
include { MAG_SUMMARY             } from '../../modules/local/mag_summary'
include { METABAT                 } from '../../modules/local/metabat'
include { MINIMAP                 } from '../../modules/local/minimap'
include { SEMIBIN                 } from '../../modules/local/semibin'


workflow BINNING {
    take:
    ch_mapping_pairs    // [ val(meta), path(reads), val(meta), path(assembly) ] one entry per mapping
    ch_assembly_to_bin  // [ val(meta), path(assembly) ] assembly with the single-contig MAGs removed
    ch_sc_mag_bins      // [ val(group), [ path(contig) ] ] one entry per group, possibly empty
    ch_gff // [ val(group), path(gff) ]

    main:
    ch_versions = channel.empty()

    // Everything inside this subworkflow is keyed by a minimal group meta map, so that
    // each process receives a proper `meta` and joins stay value-comparable.
    ch_assembly_to_join = ch_assembly_to_bin
        .map { meta, assembly -> [ [ id: meta.id ], assembly ] }

    // The pairs arrive already fanned out, one per BAM to produce: each carries the reads,
    // the assembly they are mapped against (`meta.ref`), and `n_bams`, the number of BAMs
    // that assembly will collect - known up-front - so the grouping below releases each
    // reference as soon as its own mappings are done.
    ch_mapping_pairs
        .branch { read_meta, _reads, _ref_meta, _assembly ->
            short_mapping: read_meta.type == 'short'
            long_mapping:  read_meta.type == 'long'
        }
        .set { ch_branched_inputs }

    ch_short_input = ch_branched_inputs.short_mapping
    ch_long_input  = ch_branched_inputs.long_mapping

    // Long read mapping
    ch_bam_long = MINIMAP(
        ch_long_input.map { read_meta, reads, _ref_meta, _assembly -> [ read_meta, reads ] },
        ch_long_input.map { _read_meta, _reads, ref_meta, assembly -> [ ref_meta, assembly ] }
    ).bam_pair
    ch_versions = ch_versions.mix(MINIMAP.out.versions.first())

    // Short read mapping. Each assembly is indexed once, however many read sets are mapped
    // against it: the index is several times the size of the assembly.
    ch_bwa_index = BWA_INDEX(
        ch_short_input
            .map { _read_meta, _reads, ref_meta, assembly -> [ ref_meta, assembly ] }
            .unique()
    ).index
    ch_versions = ch_versions.mix(BWA_INDEX.out.versions.first())

    ch_short_to_map = ch_short_input
        .map { read_meta, reads, ref_meta, _assembly -> [ ref_meta, read_meta, reads ] }
        .combine(ch_bwa_index, by: 0)

    ch_bam_short = BWA_MEM(
        ch_short_to_map.map { _ref_meta, read_meta, reads, _index -> [ read_meta, reads ] },
        ch_short_to_map.map { ref_meta, _read_meta, _reads, index -> [ ref_meta, index ] }
    ).bam_pair
    ch_versions = ch_versions.mix(BWA_MEM.out.versions.first())

    ch_bam_pair_mixed = ch_bam_short.mix(ch_bam_long)

    // Group BAMs + index by the assembly they were mapped against. groupKey() carries the
    // number of BAMs expected there, so binning starts as soon as that assembly is mapped
    // rather than waiting for every other one's mappings to finish.
    ch_grouped_bam_index = ch_bam_pair_mixed
        .map { meta, bam, index -> [ groupKey(meta.ref, meta.n_bams), meta, bam, index ] }
        .groupTuple()
        .map { group, metas, bams, indexes -> [ [ id: group.toString() ], metas, bams, indexes ] }

    // Aligned bases of every sample, the denominator of the coverage normalization, grouped
    // the same way as the BAMs they were counted from
    ch_group_aligned_bases = MINIMAP.out.aligned_bases
        .mix(BWA_MEM.out.aligned_bases)
        .map { meta, aligned_bases -> [ groupKey(meta.ref, meta.n_bams), aligned_bases ] }
        .groupTuple()
        .map { group, aligned_bases -> [ [ id: group.toString() ], aligned_bases ] }

    // Coverage is keyed by group only: it comes from the mappings against the full
    // assembly, so a group whose contigs all became single-contig MAGs - and which
    // therefore never reaches the binners below - still gets its stats.
    ch_group_bams = ch_grouped_bam_index
        .map { meta, _metas, bams, _indexes -> [ meta, bams ] }

    // Prepare binning channels
    ch_binning_bam = ch_assembly_to_join
        .join(ch_grouped_bam_index)

    // Run coverm contig
    ch_coverm_contig_out = COVERM_CONTIG(
        ch_group_bams, // [ meta, bam file(s) ]
    )
    ch_versions = ch_versions.mix(COVERM_CONTIG.out.versions.first())


    ch_norm_coverm_contig_in = ch_coverm_contig_out.coverm_stats
        .join(ch_group_aligned_bases)
        .join(ch_gff)

    ch_coverm_contig_norm_out = NORMALIZE_COVERM_CONTIG(
        ch_norm_coverm_contig_in.map { group, stats, aligned_bases, gff -> [ group, stats, gff, aligned_bases ] }
    )
    ch_versions = ch_versions.mix(NORMALIZE_COVERM_CONTIG.out.versions.first())

    // Binning
    // Run metabat
    ch_metabat_out = METABAT(
        ch_binning_bam.map {it -> [ it[0], it[1] ]}, // [ meta, assembly ]
        ch_binning_bam.map {it -> [ it[2], it[3] ]}  // [ meta, bam file(s) ]
    )
    ch_versions = ch_versions.mix(METABAT.out.versions.first())

    // Initialize the EXACT channels you plan to emit as empty
    ch_comebin_bins = channel.empty()
    ch_semibin_bins = channel.empty()

    if (!params.skip_comebin) {
        // Run comebin
        ch_comebin_out = COMEBIN(
            ch_binning_bam.map { meta, assembly, _metas, _bams, _indexes -> [ meta, assembly ] },
            ch_binning_bam.map { meta, _assembly, _metas, bams, _indexes -> [ meta, bams ] }
        )
        ch_comebin_bins = ch_comebin_out.comebin_bins // Assign for emit
        ch_versions = ch_versions.mix(COMEBIN.out.versions.first())
    }

    if (!params.skip_semibin) {
        // SemiBin2's sequencing type follows the BAMs it is actually given: `long_read`
        // only when every one of them comes from long reads.
        ch_semibin_input = ch_binning_bam
            .map { meta, assembly, metas, bams, _indexes ->
                [ meta, assembly, bams, metas.every { m -> m.type == 'long' } ? 'long' : 'short' ]
            }

        // Run semibin
        ch_semibin_out = SEMIBIN(
            ch_semibin_input.map { it -> [ it[0], it[1] ] },
            ch_semibin_input.map { it -> [ it[0], it[2] ] },
            ch_semibin_input.map { it -> it[3] }
        )
        ch_semibin_bins = ch_semibin_out.semibin_bins // Assign for emit
        ch_versions = ch_versions.mix(SEMIBIN.out.versions.first())
    }

    /// Combine binning results
    ch_combined_bins = ch_metabat_out.metabat_bins
        .map { group, bins -> [ group, 'metabat', bins ] }

    if (!params.skip_comebin) {
        ch_combined_bins = ch_combined_bins
            .mix( ch_comebin_bins.map { group, bins -> [ group, 'comebin', bins ] } )
    }

    if (!params.skip_semibin) {
        ch_combined_bins = ch_combined_bins
            .mix( ch_semibin_bins.map { group, bins -> [ group, 'semibin', bins ] } )
    }

    // DAS Tool. Every binner reports every group, with an empty list when it found no bins,
    // and the number of binners is known from the parameters: each group is released as
    // soon as its own binners are done. Only the bin sets that are not empty go on, and
    // their count travels with them so the contig2bin tables are regrouped the same way.
    def n_binners = 1 +
        (params.skip_comebin ? 0 : 1) +
        (params.skip_semibin ? 0 : 1)

    ch_bin_sets = ch_combined_bins
        .map { group, software, bins -> [ groupKey(group, n_binners), software, bins ] }
        .groupTuple()
        .flatMap { group, softwares, bin_lists ->
            def bin_sets = [ softwares, bin_lists ].transpose().findAll { bin_set -> bin_set[1] }
            bin_sets.collect { bin_set ->
                [ group.getGroupTarget() + [ n_bin_sets: bin_sets.size() ], bin_set[0], bin_set[1] ]
            }
        }

    ch_dastoolc2b_out = DASTOOL_CONTIG2BIN(ch_bin_sets)
        .contig2bin
        .map { meta, contig2bin -> [ groupKey([ id: meta.id ], meta.n_bin_sets), contig2bin ] }
        .groupTuple()
        .map { group, contig2bins -> [ group.getGroupTarget(), contig2bins ] }
    ch_versions = ch_versions.mix(DASTOOL_CONTIG2BIN.out.versions.first())

    ch_dastool_input = ch_assembly_to_join
        .join(ch_dastoolc2b_out)

    // Run DAS_Tool
    ch_dastool_out = DASTOOL(ch_dastool_input)
    ch_versions = ch_versions.mix(DASTOOL.out.versions.first())

    // The single-contig MAGs held out of binning re-enter here, so that everything below
    // - coverage, quality, taxonomy and the summary - treats them like any other MAG.
    // `remainder` covers the groups DAS_Tool never ran for, either because it produced no
    // bins or because the group had nothing left to bin.
    ch_final_bins = ch_sc_mag_bins
        .join(
            ch_dastool_out.dastool_bins
                .map { meta, bins -> [ meta.id, bins instanceof List ? bins : [ bins ] ] },
            remainder: true
        )
        .map { group, sc_mags, dastool_bins -> [ [ id: group ], (sc_mags ?: []) + (dastool_bins ?: []) ] }
        .filter { _meta, bins -> bins.size() > 0 }

    ch_coverm_genome_input = ch_final_bins
        .join(ch_group_bams)

    // Run CoverM
    ch_coverm_out = COVERM_GENOME(
        ch_coverm_genome_input.map { it -> [ it[0], it[1], it[2] ] }
    )
    ch_versions = ch_versions.mix(COVERM_GENOME.out.versions.first())

    ch_norm_coverm_genome_in = ch_coverm_out.coverm_stats
        .join(ch_group_aligned_bases)

    ch_coverm_genome_norm_out = NORMALIZE_COVERM_GENOME(
        ch_norm_coverm_genome_in.map { it -> [ it[0], it[1], it[2] ] }
    )
    ch_versions = ch_versions.mix(NORMALIZE_COVERM_GENOME.out.versions.first())

    // Initialize downstream variables for emit block
    ch_checkm_stats     = channel.empty()
    ch_gtdbtk_summary   = channel.empty()
    ch_mag_summary_out  = channel.empty()
    ch_final_contig2bin = channel.empty()

    if (!params.skip_bin_qa) {

        // Run CheckM
        ch_checkm_out = CHECKM(ch_final_bins)
        ch_checkm_stats = ch_checkm_out.checkm_stats // Assign for emit
        ch_versions = ch_versions.mix(CHECKM.out.versions.first())

        // Run GTDB-Tk
        if (!params.skip_gtdbtk) {
            ch_gtdbtk_out = GTDBTK(ch_final_bins, params.gtdbtk_db)
            ch_gtdbtk_summary = ch_gtdbtk_out.gtdbtk_summary // Assign for emit
            ch_versions = ch_versions.mix(GTDBTK.out.versions.first())
        }

        // Summary. When GTDB-Tk is skipped its channel is empty, so it must not be
        // joined: the join would match nothing and silently drop every group.
        ch_summarize = ch_final_bins
            .join(ch_checkm_stats)
            .join(ch_coverm_out.coverm_stats)

        ch_summarize_taxonomy = params.skip_gtdbtk
            ? ch_summarize.map { group, bins, checkm, coverm -> [ group, bins, checkm, coverm, [] ] }
            : ch_summarize.join(ch_gtdbtk_summary)

        // Run Summary
        ch_summary_run = MAG_SUMMARY(
            ch_summarize_taxonomy.map { group, bins, checkm, coverm, gtdbtk -> [ group, bins, checkm, gtdbtk, coverm ] }
        )
        ch_mag_summary_out = ch_summary_run.mag_summary // Assign for emit
        ch_final_contig2bin = ch_summary_run.contig2bin // Assign for emit
        ch_versions = ch_versions.mix(MAG_SUMMARY.out.versions.first())

    }

    // Files picked up by MultiQC. Only files a MultiQC module can parse belong here: an
    // unparseable file makes the channel non-empty without giving MultiQC anything to report,
    // and MULTIQC then fails on a report it never writes. CoverM has no MultiQC module.
    ch_multiqc_files = channel.empty()
        .mix(ch_checkm_stats.map { _meta, stats -> stats })

    emit:
    versions               = ch_versions
    multiqc_files          = ch_multiqc_files
    bam                    = ch_bam_pair_mixed
    coverm_contig_stats    = ch_coverm_contig_out.coverm_stats
    coverm_contig_norm     = ch_coverm_contig_norm_out.gene_abund_norm
    metabat_bins           = ch_metabat_out.metabat_bins
    metabat_depth          = ch_metabat_out.metabat_depth
    comebin_bins           = ch_comebin_bins
    semibin_bins           = ch_semibin_bins
    dastool_bins           = ch_dastool_out.dastool_bins
    final_bins             = ch_final_bins
    contig2bin             = ch_dastoolc2b_out
    coverm_genome_stats    = ch_coverm_out.coverm_stats
    coverm_genome_norm     = ch_coverm_genome_norm_out.coverm_genome_norm
    checkm_out             = ch_checkm_stats
    gtdbtk_out             = ch_gtdbtk_summary
    mag_summary            = ch_mag_summary_out
    final_contig2bin       = ch_final_contig2bin
}
