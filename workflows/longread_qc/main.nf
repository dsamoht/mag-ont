include { CHOPPER                  } from '../../modules/chopper'
include { PORECHOP_ABI             } from '../../modules/porechop_abi'
include { NANOPLOT as NANOPLOT_QC  } from '../../modules/nanoplot'
include { NANOPLOT as NANOPLOT_RAW } from '../../modules/nanoplot'

workflow LONGREAD_QC {
    take:
    ch_raw_long_reads
    
    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()
    
    if (!params.skip_qc) {
        if (!params.skip_nanoplot) {
            ch_nanoplot_raw_input = ch_raw_long_reads
                .map { meta, read -> [ meta, "raw", read ] }
            NANOPLOT_RAW(ch_nanoplot_raw_input)
            ch_versions = ch_versions.mix(NANOPLOT_RAW.out.versions)
        }
        
        if (!params.skip_porechop) {
            PORECHOP_ABI(ch_raw_long_reads)
            ch_versions = ch_versions.mix(PORECHOP_ABI.out.versions)
            ch_porechopped_reads = PORECHOP_ABI.out.reads
            ch_multiqc_files = ch_multiqc_files.mix(PORECHOP_ABI.out.log)
        } else {
            ch_porechopped_reads = ch_raw_long_reads
        }
        
        CHOPPER(ch_porechopped_reads)
        ch_versions = ch_versions.mix(CHOPPER.out.versions)
        ch_choppered_reads = CHOPPER.out.fastq
        
        if (!params.skip_nanoplot) {
            ch_nanoplot_qc_input = ch_choppered_reads
                .map { meta, read -> [ meta, "qc", read ] }
            NANOPLOT_QC(ch_nanoplot_qc_input)
            ch_versions = ch_versions.mix(NANOPLOT_QC.out.versions)
        }
        
        ch_long_reads_qc = ch_choppered_reads
        
    } else {
        ch_long_reads_qc = ch_raw_long_reads
    }
    
    emit:
    long_reads_qc = ch_long_reads_qc
    versions      = ch_versions
    multiqc_files = ch_multiqc_files

}
