#!/usr/bin/env nextflow


include { MAG_ONT_LR   } from './workflows/mag-ont-lr/'
include { MAG_ONT_LRSR } from './workflows/mag-ont-lrsr/'


workflow MAG_ONT {

    if (params.paired_reads != '') {
        MAG_ONT_LRSR()
    } else {
        MAG_ONT_LR()
    }
}

workflow {

    MAG_ONT()
}