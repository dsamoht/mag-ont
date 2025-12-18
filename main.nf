#!/usr/bin/env nextflow


include { MAG_ONT_LR                            } from './workflows/mag-ont-lr/'
include { MAG_ONT_LRSR                          } from './workflows/mag-ont-lrsr/'
include { MAG_ONT_KRAKEN as MAG_ONT_KRAKEN_ONLY } from './workflows/mag-ont-kraken/'
include { MAG_ONT_KRAKEN as MAG_ONT_KRAKEN_LR   } from './workflows/mag-ont-kraken/'
include { MAG_ONT_KRAKEN as MAG_ONT_KRAKEN_LRSR } from './workflows/mag-ont-kraken/'

workflow MAG_ONT {

    if (params.onlyKraken) {
        MAG_ONT_KRAKEN_ONLY()
    }

    else {
        if (params.pairedReads) {
            if (params.skipKraken){
                MAG_ONT_LRSR()
         } else {
            MAG_ONT_KRAKEN_LR()
            MAG_ONT_LRSR()
           }
        }

        else if (!params.pairedReads) {
        if (params.skipKraken){
            MAG_ONT_LR()
        } else {
            MAG_ONT_KRAKEN_LRSR()
            MAG_ONT_LR()
          }
        }
    }    
}

workflow {

    MAG_ONT()
}