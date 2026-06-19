include { CHOPPER                  } from '../../modules/chopper'
include { PORECHOP_ABI             } from '../../modules/porechop_abi'
include { NANOPLOT as NANOPLOT_QC  } from '../../modules/nanoplot'
include { NANOPLOT as NANOPLOT_RAW } from '../../modules/nanoplot'

workflow LONGREAD_QC {
    take:
    ch_raw_long_reads

    main:
    ch_versions       = channel.empty()
    ch_multiqc_files  = channel.empty()
    ch_nanoplot_raw_out = [html: channel.empty(), versions: channel.empty()]
    ch_nanoplot_qc_out  = [html: channel.empty(), versions: channel.empty()]
    ch_porechop_log   = channel.empty()

    if (!params.skip_qc) {
        if (!params.skip_nanoplot) {
            ch_nanoplot_raw_input = ch_raw_long_reads
                .map { meta, read -> [ meta, "raw", read ] }
            ch_nanoplot_raw_out = NANOPLOT_RAW(ch_nanoplot_raw_input)
            ch_versions = ch_versions.mix(ch_nanoplot_raw_out.versions.first())
        }

        if (!params.skip_porechop) {
            ch_porechop_abi_out  = PORECHOP_ABI(ch_raw_long_reads)
            ch_versions          = ch_versions.mix(ch_porechop_abi_out.versions.first())
            ch_porechopped_reads = ch_porechop_abi_out.reads
            ch_porechop_log      = ch_porechop_abi_out.log
            ch_multiqc_files     = ch_multiqc_files.mix(ch_porechop_abi_out.log)
        } else {
            ch_porechopped_reads = ch_raw_long_reads
        }

        CHOPPER(ch_porechopped_reads)
        ch_versions      = ch_versions.mix(CHOPPER.out.versions.first())
        ch_choppered_reads = CHOPPER.out.fastq

        if (!params.skip_nanoplot) {
            ch_nanoplot_qc_input = ch_choppered_reads
                .map { meta, read -> [ meta, "qc", read ] }
            ch_nanoplot_qc_out = NANOPLOT_QC(ch_nanoplot_qc_input)
            ch_versions = ch_versions.mix(ch_nanoplot_qc_out.versions.first())
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
