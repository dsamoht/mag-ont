#!/usr/bin/env nextflow

include { ASSEMBLY_WF                           } from './workflows/assembly-wf'
include { ANNOTATION_WF                         } from './workflows/annotation-wf/'
include { KRAKEN_WF as KRAKEN_ONLY              } from './workflows/kraken-wf/'
include { KRAKEN_WF as KRAKEN                   } from './workflows/kraken-wf/'


workflow METAGENOMICS_WF {

   if (params.onlyKraken) {
        KRAKEN_ONLY()
    }

   else {
        ASSEMBLY_WF()
        ASSEMBLY_WF.out.assembly.view()
        ASSEMBLY_WF.out.sorted_bam.view()        
        ANNOTATION_WF(ASSEMBLY_WF.out.assembly, ASSEMBLY_WF.out.sorted_bam)

   if (!params.skipKraken) {
        KRAKEN()
   }
   }
}

workflow {

    METAGENOMICS_WF()
}