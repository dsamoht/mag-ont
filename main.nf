#!/usr/bin/env nextflow

include { CHECKM                            } from './modules/checkm'
include { CHOPPER                           } from './modules/chopper'
include { COLLECT                           } from './modules/collect'
include { DASTOOL                           } from './modules/dastool'
include { DASTOOL_CONTIG2BIN as METABAT_C2B } from './modules/dastool_contig2bin'
include { DASTOOL_CONTIG2BIN as MAXBIN_C2B  } from './modules/dastool_contig2bin'
include { FASTQC                            } from './modules/fastqc'
include { FLYE                              } from './modules/flye'
include { GTDBTK                            } from './modules/gtdbtk'
include { MAXBIN                            } from './modules/maxbin'
include { MAXBIN_ADJUST_EXT                 } from './modules/maxbin_adjust_ext'
include { MEDAKA                            } from './modules/medaka'
include { METABAT                           } from './modules/metabat'
include { MINIMAP                           } from './modules/minimap'
include { NANOSTAT                          } from './modules/nanostat'
include { PORECHOP_ABI                      } from './modules/porechop_abi'
include { SAMTOOLS                          } from './modules/samtools'
include { SEQKIT                            } from './modules/seqkit'


info = """

                                         _   
 _ __ ___   __ _  __ _        ___  _ __ | |_ 
| '_ ` _ \\ / _` |/ _` |_____ / _ \\| '_ \\| __|
| | | | | | (_| | (_| |_____| (_) | | | | |_ 
|_| |_| |_|\\__,_|\\__, |      \\___/|_| |_|\\__|
                 |___/                       

Workflow for genome assembly with Oxford Nanopore reads.
     
     Github: https://github.com/dsamoht/mag-ont
     Version: still no release

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Usage:
     nextflow run main.nf -profile local,docker --reads PATH --outdir PATH
Input:
     -profile PROFILE(S): local/hpc (select according to available ressources), docker/singularity (container engine) default: local,docker
     --outdir PATH: path to output directory
     --reads PATH: path to raw long reads (compressed or uncompressed)
Optional flags:
     --meta : to use metagenomic mode for assembly
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

     if (params.reads == '') {
          exit 1, "Missing parameter 'reads'. Please provide an input set of reads using --reads PATH"
     }

     if (params.meta) {
          log.info "[INFO] Pipeline running in metagenomic mode"
     }
         
     reads_ch = Channel.fromPath(params.reads)
     ch_porechop_out = PORECHOP_ABI(reads_ch)
     ch_qc_reads = CHOPPER(ch_porechop_out.porechopped_reads)
     ch_nanostats_out = NANOSTAT(ch_qc_reads)
     ch_fastqc_out = FASTQC(ch_qc_reads)
     ch_flye_out = FLYE(ch_qc_reads)
     ch_medaka_out = MEDAKA(ch_qc_reads, ch_flye_out.assembly)
     ch_minimap_out = MINIMAP(ch_qc_reads, ch_medaka_out)
     ch_samtools_out = SAMTOOLS(ch_minimap_out)
     ch_metabat_out = METABAT(ch_medaka_out, ch_samtools_out)
     ch_maxbin_out = MAXBIN(ch_medaka_out, ch_metabat_out.metabat_depth)
     ch_maxbin_adjust_ext_out = MAXBIN_ADJUST_EXT(ch_maxbin_out.maxbin_bins)
     ch_metabat_c2b_out = METABAT_C2B(ch_metabat_out.metabat_bins, "metabat")
     ch_maxbin_c2b_out = MAXBIN_C2B(ch_maxbin_adjust_ext_out.renamed_maxbin_bins, "maxbin")
        
     contig2bin_ch = ch_metabat_c2b_out.
        mix(ch_maxbin_c2b_out).
        collect()

     ch_dastool_out = DASTOOL(ch_medaka_out, contig2bin_ch)
     ch_seqkit_out = SEQKIT(ch_dastool_out)
     ch_checkm_out = CHECKM(ch_dastool_out)
     ch_gtdbtk_out = GTDBTK(ch_dastool_out, params.gtdbtk_db)
     ch_collect_out = COLLECT(ch_seqkit_out, ch_checkm_out, ch_gtdbtk_out)     

}

workflow {

    MAG_ONT()
}