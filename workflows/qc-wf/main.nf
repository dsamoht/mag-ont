include { CHOPPER                                           } from '../../modules/chopper'
include { FASTP                                             } from '../../modules/fastp'

workflow QC_WF {

    take:
    ch_long_reads
    ch_short_reads

    main:
    if (params.longReads != "") {
        CHOPPER(ch_long_reads)
        filt_long_reads = CHOPPER.out
    } else {
        filt_long_reads = ch_long_reads
    }

    if (params.shortReads != "") {
        FASTP(ch_short_reads)
        filt_short_reads = FASTP.out
    } else {
        filt_short_reads = ch_short_reads
    }

    emit:
    long_reads = filt_long_reads
    short_reads = filt_short_reads
}