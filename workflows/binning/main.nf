#!usr/bin/env nextflow

include { BWA_MEM                 } from '../../modules/local/bwa'
include { CHECKM                  } from '../../modules/local/checkm'
include { CONCOCT                 } from '../../modules/local/concoct'
include { COVERM_CONTIG           } from '../../modules/local/coverm/contig'
include { COVERM_GENOME           } from '../../modules/local/coverm/genome'
include { NORMALIZE_COVERM_CONTIG } from '../../modules/local/coverm/normalize/contig'
include { NORMALIZE_COVERM_GENOME } from '../../modules/local/coverm/normalize/genome'
include { DASTOOL                 } from '../../modules/local/dastool/dastool'
include { DASTOOL_CONTIG2BIN      } from '../../modules/local/dastool/dastool_contig2bin'
include { GTDBTK                  } from '../../modules/local/gtdbtk'
include { MAG_SUMMARY             } from '../../modules/local/mag_summary'
include { MAXBIN                  } from '../../modules/local/maxbin/maxbin'
include { MAXBIN_ABUND            } from '../../modules/local/maxbin/maxbin_abundance'
include { METABAT                 } from '../../modules/local/metabat'
include { MINIMAP                 } from '../../modules/local/minimap'
include { SAMTOOLS                } from '../../modules/local/samtools'
include { SEMIBIN                 } from '../../modules/local/semibin'


workflow BINNING {
    take:
    ch_binning_wf_input // [ val(meta), path(assembly) ] full assembly, drives read mapping
    ch_assembly_to_bin  // [ val(meta), path(assembly) ] assembly with the single-contig MAGs removed
    ch_sc_mag_bins      // [ val(group), [ path(contig) ] ] one entry per group, possibly empty
    ch_gff // [ val(group), path(gff) ]

    main:
    ch_versions = channel.empty()

    // Everything inside this subworkflow is keyed by a minimal group meta map, so that
    // each process receives a proper `meta` and joins stay value-comparable.
    ch_assembly_to_join = ch_assembly_to_bin
        .map { meta, assembly -> [ [ id: meta.id ], assembly ] }

    ch_binning_wf_input
        .branch { meta, _assembly ->
            short_mapping: meta.strategy == 'short'
            long_mapping:  meta.strategy == 'long'
        }
        .set { ch_branched_inputs }

    // Logic for short read mapping. `n_bams` records how many BAMs the group will
    // produce - known up-front - so the grouping below can release each group early.
    ch_short_input = ch_branched_inputs.short_mapping
        .flatMap { meta, assembly ->
            meta.short_reads.collect { read_meta, reads ->
                [ [ read_meta + [ n_bams: meta.short_reads.size() ], reads ], [ [ id: meta.id ], assembly ] ]
            }
        }

    // Logic for long read mapping
    ch_long_input = ch_branched_inputs.long_mapping
        .flatMap { meta, assembly ->
            meta.long_reads.collect { read_meta, reads ->
                [ [ read_meta + [ n_bams: meta.long_reads.size() ], reads ], [ [ id: meta.id ], assembly ] ]
            }
        }

    // Long read mapping
    ch_sam_long = MINIMAP(
        ch_long_input.map { it[0] },
        ch_long_input.map { it[1] }
    ).sam
    ch_versions = ch_versions.mix(MINIMAP.out.versions.first())

    // Short read mapping
    ch_sam_short = BWA_MEM(
        ch_short_input.map { it[0] },
        ch_short_input.map { it[1] }
    ).sam
    ch_versions = ch_versions.mix(BWA_MEM.out.versions.first())

    ch_sam_mixed = ch_sam_short.mix(ch_sam_long)

    // Convert SAMs to sorted BAMs
    ch_bam_pair_mixed = SAMTOOLS(ch_sam_mixed)
        .bam_pair
    ch_versions = ch_versions.mix(SAMTOOLS.out.versions.first())

    // Group BAMs + index by Group ID. groupKey() carries the number of BAMs expected for
    // the group, so binning starts as soon as that group is mapped rather than waiting
    // for every other group's mappings to finish.
    ch_grouped_bam_index = ch_bam_pair_mixed
        .map { meta, bam, index -> [ groupKey(meta.group, meta.n_bams), meta, bam, index ] }
        .groupTuple()
        .map { group, metas, bams, indexes -> [ [ id: group.toString() ], metas, bams, indexes ] }

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
        .join(ch_group_bams)
        .join(ch_gff)

    ch_coverm_contig_norm_out = NORMALIZE_COVERM_CONTIG(
        ch_norm_coverm_contig_in.map { group, stats, bams, gff -> [ group, stats, gff, bams ] }
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
    ch_maxbin_abund_out = channel.empty()
    ch_maxbin_bins      = channel.empty()
    ch_concoct_bins     = channel.empty()
    ch_semibin_bins     = channel.empty()

    if (!params.skip_maxbin) {
        // Convert depth.txt to maxbin "abund"
        ch_maxbin_abund_run = MAXBIN_ABUND(ch_metabat_out.metabat_depth)
        ch_maxbin_abund_out = ch_maxbin_abund_run.maxbin_abund // Assign for emit
        ch_versions = ch_versions.mix(MAXBIN_ABUND.out.versions.first())

        // `join` already yields one entry per group: grouping again would only wrap the
        // files in single-element lists, at the cost of waiting for every group.
        ch_maxbin_input = ch_assembly_to_join
            .join(ch_maxbin_abund_out)

        // Run maxbin
        ch_maxbin_out = MAXBIN(
            ch_maxbin_input.map { it -> [ it[0], it[1] ] },
            ch_maxbin_input.map { it -> [ it[0], it[2] ] }
        )
        ch_maxbin_bins = ch_maxbin_out.maxbin_bins // Assign for emit
        ch_versions = ch_versions.mix(MAXBIN.out.versions.first())
    }

    if (!params.skip_concoct) {
        // Run concoct
        ch_concoct_out = CONCOCT(
            ch_binning_bam.map { it -> [ it[0], it[1] ] },
            ch_binning_bam.map { it -> [ it[2], it[3], it[4] ] },
        )
        ch_concoct_bins = ch_concoct_out.concoct_bins // Assign for emit
        ch_versions = ch_versions.mix(CONCOCT.out.versions.first())
    }

    if (!params.skip_semibin) {
        ch_semibin_input = ch_binning_wf_input
            .map { meta, _assembly -> [ [ id: meta.id ], meta.strategy ] }
            .join(ch_binning_bam)

        // Run semibin
        ch_semibin_out = SEMIBIN(
            ch_semibin_input.map { it -> [ it[0], it[2] ] },
            ch_semibin_input.map { it -> [ it[3], it[4] ] },
            ch_semibin_input.map { it -> it[1] }
        )
        ch_semibin_bins = ch_semibin_out.semibin_bins // Assign for emit
        ch_versions = ch_versions.mix(SEMIBIN.out.versions.first())
    }

    /// Combine binning results
    ch_combined_bins = ch_metabat_out.metabat_bins
        .map { group, bins -> [ group, 'metabat', bins ] }

    if (!params.skip_maxbin) {
        ch_combined_bins = ch_combined_bins
            .mix( ch_maxbin_bins.map { group, bins -> [ group, 'maxbin', bins ] } )
    }

    if (!params.skip_concoct) {
        ch_combined_bins = ch_combined_bins
            .mix( ch_concoct_bins.map { group, bins -> [ group, 'concoct', bins ] } )
    }

    if (!params.skip_semibin) {
        ch_combined_bins = ch_combined_bins
            .mix( ch_semibin_bins.map { group, bins -> [ group, 'semibin', bins ] } )
    }

    // DAS Tool. The number of binners is known from the parameters, so each group can be
    // released as soon as its own binners are done; `remainder` covers the binners that
    // produced no bins at all (their contig2bin output is optional).
    def n_binners = 1 +
        (params.skip_maxbin  ? 0 : 1) +
        (params.skip_concoct ? 0 : 1) +
        (params.skip_semibin ? 0 : 1)

    ch_dastoolc2b_out = DASTOOL_CONTIG2BIN(ch_combined_bins)
        .contig2bin
        .groupTuple(size: n_binners, remainder: true)
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
        .join(ch_group_bams)

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

    // Files picked up by MultiQC
    ch_multiqc_files = channel.empty()
        .mix(ch_checkm_stats.map { _meta, stats -> stats })
        .mix(ch_coverm_contig_out.coverm_stats.map { _meta, stats -> stats })

    emit:
    versions               = ch_versions
    multiqc_files          = ch_multiqc_files
    bam                    = ch_bam_pair_mixed
    coverm_contig_stats    = ch_coverm_contig_out.coverm_stats
    coverm_contig_norm     = ch_coverm_contig_norm_out.gene_abund_norm
    metabat_bins           = ch_metabat_out.metabat_bins
    metabat_depth          = ch_metabat_out.metabat_depth
    maxbin_bins            = ch_maxbin_bins
    maxbin_abund           = ch_maxbin_abund_out
    concoct_bins           = ch_concoct_bins
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
