#!/usr/bin/env nextflow

include { ASSEMBLY_WF                           } from './workflows/assembly-wf'
include { ANNOTATION_WF                         } from './workflows/annotation-wf/'
include { KRAKEN_WF as KRAKEN_ONLY              } from './workflows/kraken-wf/'
include { KRAKEN_WF as KRAKEN                   } from './workflows/kraken-wf/'
include { SETUP_WF                              } from './workflows/setup-wf/'
include { QC_WF                                 } from './workflows/qc-wf/'

info = """
   ____ _           _            __  __  ____ 
  / ___| |_   _ ___| |_ ___ _ __|  \\/  |/ ___|
 | |   | | | | / __| __/ _ \\ '__| |\\/| | |  _ 
 | |___| | |_| \\__ \\ ||  __/ |  | |  | | |_| |
  \\____|_|\\__,_|___/\\__\\___|_|  |_|  |_|\\____|

 A 2-steps workflow made to annotate and compare
 metagenomes via orthologuous clustering
     
     Github: https://github.com/dsamoht/mag-ont
     Version: still no release

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Usage:
     
     STEP 1) assembly and annotation:
     nextflow run clustermg.nf -profile hpc,singularity --longReads PATH --output PATH

     STEP 2) clustering
     nextflow run clustermg.nf -profile hpc,singularity --cluster-wf --input PATH
   
Input:

     STEP 1:
     -profile PROFILE(S): local/hpc,docker/singularity
     --output PATH: path to output directory
     --longReads PATH: path to raw long reads (compressed or uncompressed)
     --shortReads PATH: path to raw paired-end short reads (compressed or uncompressed)

     STEP 2:
     -profile PROFILE(S): local/hpc,docker/singularity
     --cluster-wf: to cluster single experiments together
     --input PATH: path to the directory containing annotated metagenomes from STEP 1.

Optional commands:
     --skipKraken: in step 1, do not run `kraken`
     --onlyKraken: in step 1, run only `kraken` (no assembly - step 2 will be unavailable)
     --hybridspades: use `spades` for hybrid assembly (default `flye`+`medaka`+`polypolish`)
"""

if( params.help ) {

log.info info
    exit 0
}

log.info info

workflow METAGENOMICS_WF {

   if (params.onlyKraken) {
        KRAKEN_ONLY()
    }

   else {
        SETUP_WF()
        if(!params.skipQC) {
          QC_WF()
          long_reads = QC_WF.out.long_reads
        } else {
          long_reads = Channel.fromPath(params.longReads)
        }
        ASSEMBLY_WF(long_reads)       
        ANNOTATION_WF(ASSEMBLY_WF.out.assembly, ASSEMBLY_WF.out.sorted_bam, ASSEMBLY_WF.out.read_type. SETUP_WF.out.diamond_db)

   if (!params.skipKraken) {
        KRAKEN(long_reads)
   }
   }
}

workflow {

    METAGENOMICS_WF()
}