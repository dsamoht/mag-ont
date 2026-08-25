#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dsamoht/mag-ont
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/dsamoht/mag-ont
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { BINNING                 } from './workflows/binning'
include { CAT_CONTIGS             } from './modules/local/cat/contig'
include { CAT_FASTQ               } from './modules/local/cat'
include { CHECKM                  } from './modules/local/checkm'
include { FILTER_HQ_SC            } from './modules/local/checkm/filter_hq_sc'
include { LONGREAD_ASSEMBLY       } from './workflows/longread_assembly'
include { LONGREAD_QC             } from './workflows/longread_qc'
include { MERGE_PYRODIGAL         } from './modules/local/pyrodigal/merge'
include { MULTIQC                 } from './modules/local/multiqc'
include { PIPELINE_INITIALISATION } from './subworkflows/local/pipeline_initialisation'
include { PYRODIGAL               } from './modules/local/pyrodigal/pyrodigal'
include { SEQKIT_SPLITBYLENGTH    } from './modules/local/seqkit'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow MAG_ONT {

    take:
    ch_samplesheet // channel: sample rows read from the sample sheet

    main:
    ch_versions      = channel.empty()
    ch_multiqc_files = channel.empty()

    // Channel of pre-existing assemblies. Everything past read QC hangs off this channel
    // and off the assemblies built below, so `--only_qc` empties both: the run then stops
    // after QC without an assembly, annotation, mapping or binning task being submitted.
    ch_input_assembly = ch_samplesheet
        .filter { sample -> !params.only_qc && sample.assembly }
        .map { sample -> [ sample.group, sample.sample_id, sample.assembly ] }
        .groupTuple(by: 0)
        .map { group, sample_ids, assemblies ->
            [ [ id: group, sample_ids: sample_ids.unique() ], assemblies[0] ]
        }

    // Channel of input short reads: every group gets an entry (an empty list when the
    // group has no short reads) so that downstream joins always match immediately
    ch_short_reads_grouped = ch_samplesheet
        .map { sample ->
            def meta = [ id: sample.sample_id, group: sample.group ]
            def entry = sample.sr1 && sample.sr2 ? [ [ meta, [ sample.sr1, sample.sr2 ] ] ] : []
            [ sample.group, entry ]
        }
        .groupTuple()
        .map { group, entries -> [ group, entries.collectMany { entry -> entry } ] }

    // Number of long read samples per group. Known as soon as the sample sheet is read,
    // so groupKey() can release each group as soon as its own samples are ready.
    ch_long_read_group_size = ch_samplesheet
        .filter { sample -> sample.long_reads }
        .map { sample -> [ sample.group, sample.sample_id ] }
        .groupTuple()
        .map { group, sample_ids -> [ group, sample_ids.size() ] }

    // Channel of input long reads
    ch_long_reads = ch_samplesheet
        .filter { sample -> sample.long_reads }
        .map { sample -> [ sample.group, sample ] }
        .combine(ch_long_read_group_size, by: 0)
        .map { group, sample, group_size ->
            [
                [
                    id           : sample.sample_id,
                    group        : group,
                    group_size   : group_size,
                    has_assembly : sample.assembly ? true : false
                ],
                sample.long_reads
            ]
        }

    ch_needs_qc = ch_long_reads
        .filter { meta, _reads -> !params.skip_qc && !meta.has_assembly }

    ch_skip_qc = ch_long_reads
        .filter { meta, _reads -> params.skip_qc || meta.has_assembly }

    //
    // SUBWORKFLOW: long read quality control
    //
    ch_qc_long_reads_out = LONGREAD_QC(ch_needs_qc)
    ch_qc_long_reads     = ch_qc_long_reads_out.long_reads_qc
    ch_long_reads_final  = ch_qc_long_reads.mix(ch_skip_qc)
    ch_versions          = ch_versions.mix(ch_qc_long_reads_out.versions)
    ch_multiqc_files     = ch_multiqc_files.mix(ch_qc_long_reads_out.multiqc_files)

    // Group reads by group. groupKey() carries the expected number of samples so a group
    // is emitted as soon as its own reads are ready, instead of waiting for every other
    // group's QC to complete.
    ch_grouped_reads = ch_long_reads_final
        .map { meta, reads -> [ groupKey(meta.group, meta.group_size), meta, reads ] }
        .groupTuple(by: 0)
        .map { group, metas, reads_list ->
            def has_assembly = metas.any { meta -> meta.has_assembly }
            def sorted_reads = reads_list.sort { a, b -> a.toString() <=> b.toString() }
            [ [ id: group.toString(), sample_ids: metas.id, has_assembly: has_assembly ], sorted_reads ]
        }

    ch_reads_to_assemble = ch_grouped_reads
        .filter { meta, _reads -> !params.only_qc && !meta.has_assembly }

    ch_qc_reads_to_assembly = CAT_FASTQ(ch_reads_to_assemble).reads
    ch_versions = ch_versions.mix(CAT_FASTQ.out.versions.first())

    //
    // SUBWORKFLOW: assemble the long reads of each group
    //
    ch_generated_assembly_out = LONGREAD_ASSEMBLY(ch_qc_reads_to_assembly)
    ch_versions = ch_versions.mix(ch_generated_assembly_out.versions)

    ch_assembly  = ch_generated_assembly_out.assembly
    ch_consensus = ch_generated_assembly_out.consensus

    ch_assembly_consensus_join = ch_assembly
        .join(ch_consensus, remainder: true)

    // For publishing: both the raw assembly and the Medaka consensus when available
    ch_assembly_to_publish = ch_assembly_consensus_join
        .flatMap { meta, assembly, consensus ->
            def results = [ [ meta + [ assembler: params.assembler ], assembly ] ]
            if (consensus) {
                results << [ meta + [ assembler: 'medaka' ], consensus ]
            }
            results
        }

    // For binning: medaka if available, otherwise flye or metamdbg
    ch_assembly_for_binning = ch_assembly_consensus_join
        .map { meta, assembly, consensus -> [ meta, consensus ?: assembly ] }
        .mix(ch_input_assembly)

    // A contig long enough to be a MAG on its own is assessed as a genome of its own, and
    // kept out of binning when it is complete enough: a contig that is already a genome
    // cannot then be split across bins or buried inside a larger one. The candidates that
    // do not make the cut are put back with the short contigs and binned as usual.
    ch_sc_mag_checkm = channel.empty()

    if (!params.skip_bin_qa) {
        //
        // MODULE: split each assembly into long and short contigs
        //
        ch_split_by_contig_lengths = SEQKIT_SPLITBYLENGTH(ch_assembly_for_binning, params.sc_mag_minimum)
        ch_versions = ch_versions.mix(SEQKIT_SPLITBYLENGTH.out.versions.first())

        // One CheckM job per group, with every candidate of that group as a genome of the
        // run, rather than one job per contig.
        ch_potential_sc_hq_mag = ch_split_by_contig_lengths.large

        ch_sc_mag_checkm = CHECKM(ch_potential_sc_hq_mag).checkm_stats
        ch_versions = ch_versions.mix(CHECKM.out.versions.first())

        //
        // MODULE: sort the candidates on completeness
        //
        ch_sc_mag_qa = FILTER_HQ_SC(
            ch_potential_sc_hq_mag.join(ch_sc_mag_checkm),
            params.sc_mag_min_completeness
        )
        ch_versions = ch_versions.mix(FILTER_HQ_SC.out.versions.first())

        //
        // MODULE: put the short contigs and the rejected candidates back together
        //
        // `remainder` covers the groups FILTER_HQ_SC did not run for, or that it rejected
        // nothing in: their assembly is rebuilt from the short contigs alone.
        ch_concat_input = ch_split_by_contig_lengths.small
            .join(ch_split_by_contig_lengths.contig_mapping)
            .join(ch_sc_mag_qa.lq_sc, remainder: true)
            .map { meta, small_fa, mapping, lq_fa -> [ meta, small_fa, lq_fa ?: [], mapping ] }

        ch_rebuilt_assembly = CAT_CONTIGS(ch_concat_input).fasta
        ch_versions = ch_versions.mix(CAT_CONTIGS.out.versions.first())

        // A group whose every contig was held out has nothing left to bin: it skips the
        // binners, and BINNING picks its MAGs up again through `ch_sc_mag_bins`.
        ch_assembly_to_bin = ch_rebuilt_assembly
            .filter { _meta, assembly -> assembly.size() > 0 }

        // BINNING joins on this, so every group needs an entry, empty or not.
        ch_sc_mag_bins = ch_rebuilt_assembly
            .map { meta, _assembly -> [ meta.id, [] ] }
            .join(
                ch_sc_mag_qa.hq_sc.map { meta, hq_sc ->
                    [ meta.id, hq_sc instanceof List ? hq_sc : [ hq_sc ] ]
                },
                remainder: true
            )
            .map { group, _none, hq_sc -> [ group, hq_sc ?: [] ] }
    }
    else {
        // Without bin QA there is no completeness to sort candidates on, so nothing is
        // held out and the binners see the assembly whole.
        ch_assembly_to_bin = ch_assembly_for_binning
        ch_sc_mag_bins     = ch_assembly_for_binning.map { meta, _assembly -> [ meta.id, [] ] }
    }

    //
    // MODULE: predict genes on 100 MB chunks of each assembly
    //
    ch_fasta_chunks = ch_assembly_for_binning
        .map { meta, assembly -> [ meta.id, assembly ] }
        .splitFasta(size: 100.MB, file: true)
        .map { group, chunk -> [ group, chunk.baseName.tokenize('.').last(), chunk ] }

    // Number of chunks per group, so MERGE_PYRODIGAL can start on a group as soon as
    // that group's own chunks are annotated
    ch_chunks_per_group = ch_fasta_chunks
        .map { group, _chunk_idx, _chunk -> [ group, 1 ] }
        .groupTuple()
        .map { group, chunks -> [ group, chunks.size() ] }

    ch_gene_chunks = PYRODIGAL(
        ch_fasta_chunks.map { group, chunk_idx, chunk -> [ [ id: group ], chunk_idx, chunk ] }
    )
    ch_versions = ch_versions.mix(PYRODIGAL.out.versions.first())

    // Pyrodigal emits the gff/fna/faa of a chunk as a single tuple, so they stay paired,
    // and the chunk index travels with them instead of being parsed back from the file
    // names at merge time.
    ch_genes_to_merge = ch_gene_chunks.genes
        .map { meta, chunk_idx, gff, fna, faa -> [ meta.id, chunk_idx, gff, fna, faa ] }
        .combine(ch_chunks_per_group, by: 0)
        .map { group, chunk_idx, gff, fna, faa, n_chunks ->
            [ groupKey(group, n_chunks), chunk_idx as Integer, gff, fna, faa ]
        }
        .groupTuple()
        .map { group, chunk_idxs, gffs, fnas, faas ->
            def ordered = [ chunk_idxs, gffs, fnas, faas ].transpose().sort { a, b -> a[0] <=> b[0] }
            [ [ id: group.toString() ],
              ordered.collect { chunk -> chunk[1] },
              ordered.collect { chunk -> chunk[2] },
              ordered.collect { chunk -> chunk[3] } ]
        }

    ch_genes = MERGE_PYRODIGAL(ch_genes_to_merge)
    ch_versions = ch_versions.mix(MERGE_PYRODIGAL.out.versions.first())

    // Groups whose samples have no long reads still need an entry, so that the join
    // below matches straight away instead of waiting on `remainder: true`
    ch_groups_without_long_reads = ch_samplesheet
        .map { sample -> [ sample.group, sample.long_reads ? 1 : 0 ] }
        .groupTuple()
        .filter { _group, flags -> flags.sum() == 0 }
        .map { group, _flags -> [ group, [] ] }

    ch_long_reads_grouped = ch_long_reads_final
        .map { meta, reads -> [ groupKey(meta.group, meta.group_size), [ meta, reads ] ] }
        .groupTuple()
        .map { group, entries -> [ group.toString(), entries ] }
        .mix(ch_groups_without_long_reads)

    ch_binning_input = ch_assembly_for_binning
        .map { meta, assembly -> [ meta.id, meta, assembly ] }
        .join(ch_long_reads_grouped)
        .join(ch_short_reads_grouped)
        .map { grp, meta, assembly, raw_long, raw_short ->
            def sorted_long  = raw_long.sort  { a, b -> a[0].id <=> b[0].id }
            def sorted_short = raw_short.sort { a, b -> a[0].id <=> b[0].id }

            def new_meta = meta + [
                id          : grp,
                strategy    : sorted_short.size() > 0 ? 'short' : 'long',
                long_reads  : sorted_long,
                short_reads : sorted_short
            ]

            [ new_meta, assembly ]
        }

    //
    // SUBWORKFLOW: map reads, bin contigs and assess the resulting MAGs
    //
    // Reads are mapped against the full assembly (`ch_binning_input`) so that coverage
    // stays correct and the held-out single-contig MAGs keep an abundance estimate, while
    // the binners only ever see `ch_assembly_to_bin`.
    //
    // The gene predictions are only needed to normalize contig coverage, so they are
    // passed separately: mapping and binning must not wait for Pyrodigal.
    //
    BINNING(ch_binning_input, ch_assembly_to_bin, ch_sc_mag_bins, ch_genes.gff)
    ch_versions      = ch_versions.mix(BINNING.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(BINNING.out.multiqc_files)

    //
    // Collate software versions
    //
    // Collect the contents rather than the paths: `sort: true` orders the entries by their
    // value, and a channel of paths sorts by work directory, which is a fresh random hash on
    // every run. Reading each file first makes both the deduplication and the order depend on
    // the versions themselves, so the published file is the same from one run to the next.
    ch_collated_versions = ch_versions
        .map { versions -> versions.text }
        .unique()
        .collectFile(name: 'mag-ont_software_mqc_versions.yml', sort: true)

    //
    // MODULE: MultiQC
    //
    ch_multiqc_report = channel.empty()
    if (!params.skip_multiqc) {
        ch_multiqc_config = channel.fromPath("${projectDir}/assets/multiqc_config.yml", checkIfExists: true)
        ch_multiqc_custom_config = params.multiqc_config
            ? channel.fromPath(params.multiqc_config, checkIfExists: true)
            : channel.empty()
        ch_multiqc_logo = params.multiqc_logo
            ? channel.fromPath(params.multiqc_logo, checkIfExists: true)
            : channel.empty()

        // MultiQC exits without writing a report when its search finds nothing it can parse,
        // and the software versions file is not one of the things it parses. `collect()`
        // emits nothing when no step produced a report of its own — with `--only_qc` and
        // NanoPlot and Porechop both skipped, for instance — so MULTIQC is not submitted at
        // all instead of failing on a report it never wrote.
        ch_multiqc_input = ch_multiqc_files
            .collect()
            .combine(ch_collated_versions)

        MULTIQC(
            ch_multiqc_input,
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList()
        )
        ch_multiqc_report = MULTIQC.out.report
        ch_versions = ch_versions.mix(MULTIQC.out.versions)
    }

    emit:
    versions               = ch_collated_versions
    multiqc_report         = ch_multiqc_report
    nanoplot_raw_html      = ch_qc_long_reads_out.nanoplot_raw_html
    nanoplot_qc_html       = ch_qc_long_reads_out.nanoplot_qc_html
    porechop_log           = ch_qc_long_reads_out.porechop_log
    qc_long_reads          = ch_qc_long_reads
    input_assembly         = ch_input_assembly
    assembly               = ch_assembly_to_publish
    sc_mag_checkm          = ch_sc_mag_checkm
    pyrodigal_gff          = ch_genes.gff
    pyrodigal_fna          = ch_genes.fna
    pyrodigal_faa          = ch_genes.faa
    bam                    = BINNING.out.bam
    coverm_contig_stats    = BINNING.out.coverm_contig_stats
    coverm_contig_norm     = BINNING.out.coverm_contig_norm
    metabat_bins           = BINNING.out.metabat_bins
    metabat_depth          = BINNING.out.metabat_depth
    maxbin_bins            = BINNING.out.maxbin_bins
    maxbin_abund           = BINNING.out.maxbin_abund
    concoct_bins           = BINNING.out.concoct_bins
    semibin_bins           = BINNING.out.semibin_bins
    dastool_bins           = BINNING.out.dastool_bins
    final_bins             = BINNING.out.final_bins
    contig2bin             = BINNING.out.contig2bin
    coverm_genome_stats    = BINNING.out.coverm_genome_stats
    coverm_genome_norm     = BINNING.out.coverm_genome_norm
    checkm_out             = BINNING.out.checkm_out
    gtdbtk_out             = BINNING.out.gtdbtk_out
    mag_summary            = BINNING.out.mag_summary
    final_contig2bin       = BINNING.out.final_contig2bin
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN THE WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: validate the parameters and read the sample sheet
    //
    PIPELINE_INITIALISATION(
        params.validate_params,
        params.input,
        params.help,
        params.help_full,
        params.show_hidden
    )

    //
    // WORKFLOW: run the main analysis
    //
    MAG_ONT(PIPELINE_INITIALISATION.out.samplesheet)

    publish:
    versions               = MAG_ONT.out.versions
    multiqc_report         = MAG_ONT.out.multiqc_report
    nanoplot_raw_html      = MAG_ONT.out.nanoplot_raw_html
    nanoplot_qc_html       = MAG_ONT.out.nanoplot_qc_html
    porechop_log           = MAG_ONT.out.porechop_log
    qc_long_reads          = MAG_ONT.out.qc_long_reads
    input_assembly         = MAG_ONT.out.input_assembly
    assembly               = MAG_ONT.out.assembly
    sc_mag_checkm          = MAG_ONT.out.sc_mag_checkm
    pyrodigal_gff          = MAG_ONT.out.pyrodigal_gff
    pyrodigal_fna          = MAG_ONT.out.pyrodigal_fna
    pyrodigal_faa          = MAG_ONT.out.pyrodigal_faa
    bam                    = MAG_ONT.out.bam
    coverm_contig_stats    = MAG_ONT.out.coverm_contig_stats
    coverm_contig_norm     = MAG_ONT.out.coverm_contig_norm
    metabat_bins           = MAG_ONT.out.metabat_bins
    metabat_depth          = MAG_ONT.out.metabat_depth
    maxbin_bins            = MAG_ONT.out.maxbin_bins
    maxbin_abund           = MAG_ONT.out.maxbin_abund
    concoct_bins           = MAG_ONT.out.concoct_bins
    semibin_bins           = MAG_ONT.out.semibin_bins
    dastool_bins           = MAG_ONT.out.dastool_bins
    final_bins             = MAG_ONT.out.final_bins
    contig2bin             = MAG_ONT.out.contig2bin
    coverm_genome_stats    = MAG_ONT.out.coverm_genome_stats
    coverm_genome_norm     = MAG_ONT.out.coverm_genome_norm
    checkm_out             = MAG_ONT.out.checkm_out
    gtdbtk_out             = MAG_ONT.out.gtdbtk_out
    mag_summary            = MAG_ONT.out.mag_summary
    final_contig2bin       = MAG_ONT.out.final_contig2bin
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PUBLISH TARGETS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

output {
    qc_long_reads {
        path { meta, _file -> "group_${meta.group}/reads/post_qc" }
    }
    nanoplot_raw_html {
        path { meta, _file -> "group_${meta.group}/quality_assessment/nanoplot/raw/${meta.id}" }
    }
    nanoplot_qc_html {
        path { meta, _file -> "group_${meta.group}/quality_assessment/nanoplot/post_qc/${meta.id}" }
    }
    porechop_log {
        path { meta, _file -> "group_${meta.group}/quality_control/porechop" }
    }
    assembly {
        path { meta, _file -> "group_${meta.id}/assembly/${meta.assembler}" }
    }
    input_assembly {
        path { meta, _file -> "group_${meta.id}/assembly/provided" }
    }
    sc_mag_checkm {
        path { meta, _file -> "group_${meta.id}/binning/single_contig_mags" }
    }
    pyrodigal_gff {
        path { meta, _file -> "group_${meta.id}/assembly/pyrodigal" }
    }
    pyrodigal_fna {
        path { meta, _file -> "group_${meta.id}/assembly/pyrodigal" }
    }
    pyrodigal_faa {
        path { meta, _file -> "group_${meta.id}/assembly/pyrodigal" }
    }
    bam {
        path { meta, _bam, _bai -> "group_${meta.group}/mapping/samtools" }
    }
    coverm_contig_stats {
        path { meta, _file -> "group_${meta.id}/mapping/coverm" }
    }
    coverm_contig_norm {
        path { meta, _file -> "group_${meta.id}/mapping/genes" }
    }
    metabat_bins {
        path { meta, _file -> "group_${meta.id}/binning/metabat" }
    }
    metabat_depth {
        path { meta, _file -> "group_${meta.id}/binning/metabat" }
    }
    maxbin_bins {
        path { meta, _file -> "group_${meta.id}/binning/maxbin" }
    }
    maxbin_abund {
        path { meta, _file -> "group_${meta.id}/binning/maxbin" }
    }
    concoct_bins {
        path { meta, _file -> "group_${meta.id}/binning/concoct" }
    }
    semibin_bins {
        path { meta, _file -> "group_${meta.id}/binning/semibin" }
    }
    dastool_bins {
        path { meta, _file -> "group_${meta.id}/binning/dastool" }
    }
    contig2bin {
        path { meta, _file -> "group_${meta.id}/binning/contig2bin" }
    }
    final_bins {
        path { meta, _file -> "group_${meta.id}/binning/final_bins" }
    }
    coverm_genome_stats {
        path { meta, _file -> "group_${meta.id}/binning/coverm" }
    }
    coverm_genome_norm {
        path { meta, _file -> "group_${meta.id}/binning/coverm" }
    }
    checkm_out {
        path { meta, _file -> "group_${meta.id}/binning/checkm" }
    }
    gtdbtk_out {
        path { meta, _file -> "group_${meta.id}/binning/gtdbtk" }
    }
    mag_summary {
        path { meta, _file -> "group_${meta.id}/binning/summary" }
    }
    final_contig2bin {
        path { meta, _file -> "group_${meta.id}/binning/summary" }
    }
    multiqc_report {
        path "multiqc"
    }
    versions {
        path "pipeline_info"
    }
}
