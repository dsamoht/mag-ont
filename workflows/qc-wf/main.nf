include { CHOPPER                                           } from '../../modules/chopper'

workflow QC_WF {

    take:
    ch_long_reads
    ch_short_reads

    main:
    if (params.longReads != "") {
        CHOPPER(ch_long_reads)
        filt_long_reads = CHOPPER.out
    }

    filt_short_reads = ch_short_reads

    emit:
    long_reads = filt_long_reads
    short_reads = filt_short_reads
}