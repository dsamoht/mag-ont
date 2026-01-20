#!usr/bin/env nextflow

include { BWA_MEM            } from '../../modules/bwa'
include { CHECKM             } from '../../modules/checkm'
include { COMEBIN            } from '../../modules/comebin'
include { CONCOCT            } from '../../modules/concoct'
include { COVERM             } from '../../modules/coverm'
include { DASTOOL            } from '../../modules/dastool/dastool'
include { DASTOOL_CONTIG2BIN } from '../../modules/dastool/dastool_contig2bin'
include { GTDBTK             } from '../../modules/gtdbtk'
include { MAXBIN             } from '../../modules/maxbin/maxbin'
include { MAXBIN_ABUND       } from '../../modules/maxbin/maxbin_abundance'
include { METABAT            } from '../../modules/metabat'
include { MINIMAP            } from '../../modules/minimap'
include { SAMTOOLS           } from '../../modules/samtools'
include { SEMIBIN            } from '../../modules/semibin'


workflow BINNING {
    take:
    ch_binning_wf_input // [ meta, assembly ]

    main:
    ch_versions = channel.empty()

    ch_assembly_to_join = ch_binning_wf_input
        .map { meta, assembly -> [ meta.group, assembly ] }

    ch_binning_wf_input
        .branch { meta, assembly ->
            short_mapping: meta.strategy == 'short'
            long_mapping:  meta.strategy == 'long'
        }
        .set { ch_branched_inputs }

    // Logic for short read mapping
    ch_short_input = ch_branched_inputs.short_mapping
        .map{ meta, assembly -> [ meta.short_reads, assembly ] }
        .transpose()
        .map { reads, assembly -> [ reads, [ reads[0].group, assembly ] ] }

    // Logic for long read mapping
    ch_long_input = ch_branched_inputs.long_mapping
        .map{ meta, assembly -> [ meta.long_reads, assembly ] }
        .transpose()
        .map { reads, assembly -> [ reads, [ reads[0].group, assembly ] ] }

    // Long read mapping
    ch_sam_long = MINIMAP(
        ch_long_input.map { it[0] },
        ch_long_input.map { it[1] }
    ).sam

    // Short read mapping
    ch_sam_short = BWA_MEM(
        ch_short_input.map { it[0] },
        ch_short_input.map { it[1] }
    ).sam

    ch_sam_mixed = ch_sam_short.mix(ch_sam_long)

    // Convert SAMs to sorted BAMs
    ch_bam_pair_mixed = SAMTOOLS(ch_sam_mixed)
        .bam_pair

    // Group BAMs + index by Group ID
    ch_grouped_bam_index = ch_bam_pair_mixed
        .map { meta, bam, index -> [ meta.group, meta, bam, index ] }
        .groupTuple()

    // Prepare binning channels
    ch_binning_bam = ch_assembly_to_join
        .join(ch_grouped_bam_index)

    // Binning
    // Run metabat
    ch_metabat_out = METABAT(
        ch_binning_bam.map {it -> [ it[0], it[1] ]}, // [ meta, assembly ]
        ch_binning_bam.map {it -> [ it[2], it[3] ]}  // [ meta, bam file(s) ]
    )
    if (!params.skip_maxbin) {
        // Convert depth.txt to maxbin "abund"
        ch_maxbin_abund = MAXBIN_ABUND(
            ch_metabat_out.metabat_depth
        )

        ch_maxbin_input = ch_assembly_to_join
            .join(ch_maxbin_abund)
            .groupTuple()

        // Run maxbin
        ch_maxbin_out = MAXBIN(
            ch_maxbin_input.map { it -> [ it[0], it[1] ] }, // [ meta, assembly ]
            ch_maxbin_input.map { it -> [ it[0], it[2] ] }  // [ meta, maxbin_abund ]
        )
    }

    if (!params.skip_concoct) {
        // Run concoct
        ch_concoct_out = CONCOCT(
            ch_binning_bam.map { it -> [ it[0], it[1] ] }, // [ meta, assembly ]
            ch_binning_bam.map { it -> [ it[2], it[3] ] }, // [ meta, bam file(s) ]
            ch_binning_bam.map { it -> [ it[2], it[4] ] }, // [ meta, bai file(s) ]
        )
    }
    
    if (!params.skip_semibin) {

        ch_semibin_input = ch_binning_wf_input
        .map { meta, assembly -> [ meta.group, meta.strategy ] }
        .join(ch_binning_bam)
    
        // Run semibin
        ch_semibin_out = SEMIBIN(
            ch_semibin_input.map { it -> [ it[0], it[2] ] }, // [ meta, assembly ]
            ch_semibin_input.map { it -> [ it[3], it[4] ] }, // [ meta, bam file(s) ]
            ch_semibin_input.map { it -> it[1] }             // strategy_type
        )
    }

    /// Combine binning results
    ch_combined_bins = ch_metabat_out.metabat_bins
        .map { group, bins -> [ group, 'metabat', bins ] }

    if (!params.skip_maxbin) {
        ch_combined_bins = ch_combined_bins
            .mix( ch_maxbin_out.maxbin_bins.map { group, bins -> [ group, 'maxbin', bins ] } )
    }

    if (!params.skip_concoct) {
        ch_combined_bins = ch_combined_bins
            .mix( ch_concoct_out.concoct_bins.map { group, bins -> [ group, 'concoct', bins ] } )
    }

    if (!params.skip_semibin) {
        ch_combined_bins = ch_combined_bins
            .mix( ch_semibin_out.semibin_bins.map { group, bins -> [ group, 'semibin', bins ] } )
    }
    
    // DAS Tool
    ch_dastoolc2b_out = DASTOOL_CONTIG2BIN(ch_combined_bins)
        .contig2bin
        .groupTuple()

    ch_dastool_input = ch_assembly_to_join
        .join(ch_dastoolc2b_out)

    // Run DAS_Tool
    ch_dastool_out = DASTOOL(ch_dastool_input)
    
    // Run CheckM
    ch_checkm_out = CHECKM(
        ch_dastool_out.dastool_bins
    )
    
    // Run GTDB-Tk
    ch_gtdbtk_out = GTDBTK(
    ch_dastool_out.dastool_bins,
        params.gtdbtk_db
    )
    ch_coverm_input = ch_dastool_out.dastool_bins
        .join(
        ch_binning_bam.map { it -> [ it[0], it[3] ] } // [ meta, bam files(s)]
        )

    // Run CoverM
    ch_coverm_out = COVERM(
        ch_coverm_input.map { it -> [ it[0], it[1] ] }, // [ meta, bin(s) ]
        ch_coverm_input.map { it -> [ it[0], it[2] ] }  // [ meta, bam files(s) ]
    )

        // Summary
    ch_summarize = ch_dastool_out.dastool_bins           // [group, [bin1.fa, bin2.fa]]
        .join(ch_checkm_out.checkm_stats)                   // [group, bins, checkm_tsv]
        .join(ch_coverm_out.coverm_stats)               // [group, bins, checkm, coverm_tsv]
        .join(ch_gtdbtk_out.gtdbtk_summary)

    // Run Summary
    ch_summary_out = MAG_SUMMARY(
        ch_summarize.map{ it -> [ it[0], it[1] ] },
        ch_summarize.map{ it -> [ it[0], it[2] ] },
        ch_summarize.map{ it -> [ it[0], it[4] ] },
        ch_summarize.map{ it -> [ it[0], it[3] ] }
    )

}
