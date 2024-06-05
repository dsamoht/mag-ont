include { CHOPPER                                           } from '../../modules/chopper'

workflow QC_WF {

    main:
    if (params.longReads != "") {
        reads = Channel.fromPath(params.longReads)
        CHOPPER(reads)
        filt_long_reads = CHOPPER.out
    } 

    emit:
    long_reads = filt_long_reads
}