#!usr/bin/env nextflow

include { BWA_MEM                 } from '../../modules/bwa'
include { CHECKM                  } from '../../modules/checkm'
include { CONCOCT                 } from '../../modules/concoct'
include { COVERM_CONTIG           } from '../../modules/coverm/contig'
include { COVERM_GENOME           } from '../../modules/coverm/genome'
include { NORMALIZE_COVERM_CONTIG } from '../../modules/coverm/normalize/contig'
include { NORMALIZE_COVERM_GENOME } from '../../modules/coverm/normalize/genome'
include { DASTOOL                 } from '../../modules/dastool/dastool'
include { DASTOOL_CONTIG2BIN      } from '../../modules/dastool/dastool_contig2bin'
include { GTDBTK                  } from '../../modules/gtdbtk'
include { MAG_SUMMARY             } from '../../modules/mag_summary'
include { MAXBIN                  } from '../../modules/maxbin/maxbin'
include { MAXBIN_ABUND            } from '../../modules/maxbin/maxbin_abundance'
include { METABAT                 } from '../../modules/metabat'
include { MINIMAP                 } from '../../modules/minimap'
include { SAMTOOLS                } from '../../modules/samtools'
include { SEMIBIN                 } from '../../modules/semibin'


workflow BINNING {
    take:
    ch_binning_wf_input

    main:
    ch_versions = channel.empty()

    ch_assembly_to_join = ch_binning_wf_input
        .map { meta, assembly -> [ meta.group, assembly ] }

    ch_binning_wf_input
        .branch { meta, _assembly ->
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

    // Group BAMs + index by Group ID
    ch_grouped_bam_index = ch_bam_pair_mixed
        .map { meta, bam, index -> [ meta.group, meta, bam, index ] }
        .groupTuple()

    // Prepare binning channels
    ch_binning_bam = ch_assembly_to_join
        .join(ch_grouped_bam_index)

    // Run coverm contig
    ch_coverm_contig_out = COVERM_CONTIG(
        ch_binning_bam.map {it -> [ it[0], it[3] ]}, // [ meta, bam file(s) ]
    )
    ch_versions = ch_versions.mix(COVERM_CONTIG.out.versions.first())

    
    ch_norm_coverm_contig_in = ch_coverm_contig_out.coverm_stats
        .join(
            ch_binning_bam.map { it -> [ it[0], it[3] ] }
        )
        .join(
            ch_binning_wf_input.map { meta, _assembly -> [ meta.group, meta.gff ] }
        )

    ch_coverm_contig_norm_out = NORMALIZE_COVERM_CONTIG(
        ch_norm_coverm_contig_in.map { it -> [ it[0], it[1], it[3], it[2] ] } // [ meta, coverm_stats, gff file, bam files(s) ]
    )

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

        ch_maxbin_input = ch_assembly_to_join
            .join(ch_maxbin_abund_out)
            .groupTuple()

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
            .map { meta, _assembly -> [ meta.group, meta.strategy ] }
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
    
    // DAS Tool
    ch_dastoolc2b_out = DASTOOL_CONTIG2BIN(ch_combined_bins)
        .contig2bin
        .groupTuple()

    ch_dastool_input = ch_assembly_to_join
        .join(ch_dastoolc2b_out)

    // Run DAS_Tool
    ch_dastool_out = DASTOOL(ch_dastool_input)
    ch_versions = ch_versions.mix(DASTOOL.out.versions.first())

    ch_coverm_genome_input = ch_dastool_out.dastool_bins
        .join(ch_binning_bam.map { it -> [ it[0], it[3] ] }) 

    // Run CoverM
    ch_coverm_out = COVERM_GENOME(
        ch_coverm_genome_input.map { it -> [ it[0], it[1], it[2] ] }
    )
    ch_versions = ch_versions.mix(COVERM_GENOME.out.versions.first())

    ch_norm_coverm_genome_in = ch_coverm_out.coverm_stats
        .join(ch_binning_bam.map { it -> [ it[0], it[3] ] })

    ch_coverm_genome_norm_out = NORMALIZE_COVERM_GENOME(
        ch_norm_coverm_genome_in.map { it -> [ it[0], it[1], it[2] ] }
    )

    // Initialize downstream variables for emit block
    ch_checkm_stats     = channel.empty()
    ch_gtdbtk_summary   = channel.empty()
    ch_mag_summary_out  = channel.empty()
    ch_final_contig2bin = channel.empty()

    if (!params.skip_bin_qa) {
    
        // Run CheckM
        ch_checkm_out = CHECKM(ch_dastool_out.dastool_bins)
        ch_checkm_stats = ch_checkm_out.checkm_stats // Assign for emit
        ch_versions = ch_versions.mix(CHECKM.out.versions.first())
        
        // Run GTDB-Tk
        ch_gtdbtk_out = GTDBTK(ch_dastool_out.dastool_bins, params.gtdbtk_db)
        ch_gtdbtk_summary = ch_gtdbtk_out.gtdbtk_summary // Assign for emit
        ch_versions = ch_versions.mix(GTDBTK.out.versions.first())

        // Summary
        ch_summarize = ch_dastool_out.dastool_bins
            .join(ch_checkm_stats)
            .join(ch_coverm_out.coverm_stats)
            .join(ch_gtdbtk_summary)

        // Run Summary
        ch_summary_run = MAG_SUMMARY(
            ch_summarize.map{ it -> [ it[0], it[1], it[2], it[4], it[3] ] }
        )
        ch_mag_summary_out = ch_summary_run.mag_summary // Assign for emit
        ch_final_contig2bin = ch_summary_run.contig2bin // Assign for emit

    }

    emit:
    versions               = ch_versions
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
    contig2bin             = ch_dastoolc2b_out
    coverm_genome_stats    = ch_coverm_out.coverm_stats
    coverm_genome_norm     = ch_coverm_genome_norm_out.coverm_genome_norm
    checkm_out             = ch_checkm_stats
    gtdbtk_out             = ch_gtdbtk_summary
    mag_summary            = ch_mag_summary_out
    final_contig2bin       = ch_final_contig2bin
}
