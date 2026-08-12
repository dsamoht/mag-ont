#!/usr/bin/env nextflow

include { CHOPPER                  } from '../../modules/local/chopper'
include { PORECHOP_ABI             } from '../../modules/local/porechop_abi'
include { NANOPLOT as NANOPLOT_QC  } from '../../modules/local/nanoplot'
include { NANOPLOT as NANOPLOT_RAW } from '../../modules/local/nanoplot'

workflow LONGREAD_QC {
    take:
    ch_raw_long_reads // channel: [ val(meta), path(reads) ]

    main:
    ch_versions         = channel.empty()
    ch_multiqc_files    = channel.empty()
    ch_nanoplot_raw_out = [ html: channel.empty(), txt: channel.empty(), versions: channel.empty() ]
    ch_nanoplot_qc_out  = [ html: channel.empty(), txt: channel.empty(), versions: channel.empty() ]
    ch_porechop_log     = channel.empty()

    if (!params.skip_qc) {
        //
        // MODULE: read quality report before trimming
        //
        if (!params.skip_nanoplot) {
            ch_nanoplot_raw_out = NANOPLOT_RAW(ch_raw_long_reads)
            ch_versions         = ch_versions.mix(NANOPLOT_RAW.out.versions.first())
            ch_multiqc_files    = ch_multiqc_files.mix(ch_nanoplot_raw_out.txt.map { _meta, txt -> txt })
        }

        //
        // MODULE: adapter removal
        //
        if (!params.skip_porechop) {
            ch_porechop_abi_out  = PORECHOP_ABI(ch_raw_long_reads)
            ch_versions          = ch_versions.mix(PORECHOP_ABI.out.versions.first())
            ch_porechopped_reads = ch_porechop_abi_out.reads
            ch_porechop_log      = ch_porechop_abi_out.log
            ch_multiqc_files     = ch_multiqc_files.mix(ch_porechop_abi_out.log.map { _meta, log -> log })
        } else {
            ch_porechopped_reads = ch_raw_long_reads
        }

        //
        // MODULE: length and quality filtering
        //
        CHOPPER(ch_porechopped_reads)
        ch_versions        = ch_versions.mix(CHOPPER.out.versions.first())
        ch_choppered_reads = CHOPPER.out.fastq

        //
        // MODULE: read quality report after trimming
        //
        if (!params.skip_nanoplot) {
            ch_nanoplot_qc_out = NANOPLOT_QC(ch_choppered_reads)
            ch_versions        = ch_versions.mix(NANOPLOT_QC.out.versions.first())
            ch_multiqc_files   = ch_multiqc_files.mix(ch_nanoplot_qc_out.txt.map { _meta, txt -> txt })
        }

        ch_long_reads_qc = ch_choppered_reads
    } else {
        ch_long_reads_qc = ch_raw_long_reads
    }

    emit:
    nanoplot_raw_html = ch_nanoplot_raw_out.html
    nanoplot_qc_html  = ch_nanoplot_qc_out.html
    porechop_log      = ch_porechop_log
    long_reads_qc     = ch_long_reads_qc
    versions          = ch_versions
    multiqc_files     = ch_multiqc_files
}
