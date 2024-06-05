include { CHOPPER                                           } from '../../modules/chopper'

workflow QC_WF {

    main:
    if (params.longReads != "" && !params.skipQC) {
        reads = Channel.fromPath(params.longReads)
        CHOPPER(reads)
        filt_long_reads = CHOPPER.out
    } else {
        filt_long_reads = Channel.fromPath(params.longReads)
    }

    emit:
    long_reads = filt_long_reads
}