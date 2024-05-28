include { CHOPPER                                           } from '../../modules/chopper'

workflow QC_WF {

    main:
    if (params.longReads != "") {
        long_reads = Channel.fromPath(params.longReads)
        CHOPPER(long_reads)
        filt_long_reads = CHOPPER.out
    }

    emit:
    filt_long_reads = filt_long_reads
}


}