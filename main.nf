#!/usr/bin/env nextflow

include { DISPATCH    } from './workflows/dispatch'
include { LONGREAD_QC } from './workflows/longread_qc'


info = """
                                         _   
 _ __ ___   __ _  __ _        ___  _ __ | |_ 
| '_ ` _ \\ / _` |/ _` |_____ / _ \\| '_ \\| __|
| | | | | | (_| | (_| |_____| (_) | | | | |_ 
|_| |_| |_|\\__,_|\\__, |      \\___/|_| |_|\\__|
                 |___/                       

Workflow for metagenome assembly and binning
tailored for Oxford Nanopore reads.
     
     Github: https://github.com/dsamoht/mag-ont
     Version: still no release

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Usage:
     nextflow run main.nf -profile local,docker --input FILE --outdir PATH
Input:
     -profile PROFILE(S): local/hpc (select according to available ressources), docker/singularity (container engine) default: local,docker
     --outdir PATH: path to output directory
     --input FILE: path to input samplesheet (CSV format)
"""

if( params.help ) {

log.info info
    exit 0
}

log.info info


workflow MAG_ONT {

     if (!params.outdir) {
          exit 1, "Missing parameter 'outdir'. Please provide an output directory using --outdir PATH"
     }

     if (params.input == '') {
          exit 1, "Missing parameter 'input'. Please provide a sample sheet using --input FILE"
     }
     
     ch_dispatched = DISPATCH()
     //ch_qc = LONGREAD_QC(ch_dispatched)

}

workflow {

    MAG_ONT()
}