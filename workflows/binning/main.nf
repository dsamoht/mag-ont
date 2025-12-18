workflow BINNING_WF {

    take:
    assembly_ch
    reads_ch

    main:

    assembly_reads_pairs_ch = assembly_ch.combine(reads_ch)

    MINIMAP_OUT      = MINIMAP(assembly_reads_pairs_ch)
    SAMTOOLS_OUT     = SAMTOOLS(MINIMAP_OUT.sam)
    BAM_FILES        = SAMTOOLS_OUT.bam_pair
		           .map {bam, index -> return bam }
                           .collect()
    BAM_PAIRS        = SAMTOOLS_OUT.bam_pair.collect()

    METABAT_OUT      = METABAT(assembly_ch, BAM_FILES)
    MAXBIN_ABUND_OUT = MAXBIN_ABUND(METABAT_OUT.metabat_depth)
    MAXBIN_OUT       = MAXBIN(assembly_ch, MAXBIN_ABUND_OUT.maxbin_abund)
    CONCOCT_OUT      = CONCOCT(assembly_ch, BAM_PAIRS)
    SEMIBIN_OUT      = SEMIBIN(assembly_ch, BAM_FILES)

    METABAT_OUT.metabat_bins.map { bins -> [ bins, "metabat" ] }
	.mix(MAXBIN_OUT.maxbin_bins.map { bins -> [ bins, "maxbin"  ] })
	.mix(CONCOCT_OUT.concoct_bins.map { bins  -> [ bins, "concoct" ] })
        .mix(SEMIBIN_OUT.semibin_bins.map { bins -> [ bins, "semibin" ] })
        .set { DASTOOL_C2B_IN }


    DASTOOL_C2B_OUT = DASTOOL_CONTIG2BIN(DASTOOL_C2B_IN)

    DASTOOL_IN = DASTOOL_C2B_OUT.collect()

    DASTOOL_OUT = DASTOOL(assembly_ch, DASTOOL_IN)

    BINS_QC_IN = DASTOOL_OUT.dasBins

    CHECKM_OUT = CHECKM(BINS_QC_IN)
    GTDBTK_OUT = GTDBTK(BINS_QC_IN, params.gtdbtk_db)
    COVERM_OUT = COVERM(BINS_QC_IN, BAM_FILES)

    emit:
    metabat_bins = METABAT_OUT.metabat_bins
    maxbin_bins  = MAXBIN_OUT.maxbin_bins
    concoct_bins = CONCOCT_OUT.concoct_bins
    semibin_bins = SEMIBIN_OUT.semibin_bins
    das_bins     = DASTOOL_OUT.dasBins

}
