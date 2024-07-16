#!/usr/bin/env nextflow

include { ASSEMBLY_WF                           } from './workflows/assembly-wf/'
include { ANNOTATION_WF                         } from './workflows/annotation-wf/'
include { KRAKEN_WF as KRAKEN_ONLY              } from './workflows/kraken-wf/'
include { KRAKEN_WF as KRAKEN                   } from './workflows/kraken-wf/'
include { SETUP_WF                              } from './workflows/setup-wf/'
include { QC_WF                                 } from './workflows/qc-wf/'
include { GROUP_WF                              } from './workflows/group-wf/'

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
     nextflow run clustermg.nf -profile hpc,singularity --longReads PATH --outdir PATH --fastaDBs PATH

     STEP 2) clustering
     nextflow run clustermg.nf -profile hpc,singularity --step2 --step2_sheet PATH --outdir PATH
   
Input:

     STEP 1:
     -profile PROFILE(S): local/hpc,docker/singularity
     --outdir PATH: path to output directory
     --longReads PATH: path to raw long reads (compressed or uncompressed)
     --shortReads PATH: path to raw paired-end short reads (compressed or uncompressed)

     STEP 2:
     -profile PROFILE(S): local/hpc,docker/singularity
     --outdir PATH: path to output directory
     --step2: to cluster single experiments together
     --step2_sheet PATH: path to tsv file containing result directory path for each sample

Optional commands:
     --skipKraken: in step 1, do not run `kraken`
     --onlyKraken: in step 1, run only `kraken` (no assembly - step 2 will be unavailable)
     --skipQC: in step 1, skip the quality control step
     --hybridspades: in step 1, use `spades` for hybrid assembly (default `flye`+`medaka`+`polypolish`)
     --sampleName: in step 1, name of the sample, all sample names in step 2 must be unique (default file name)
     --fastaDBs PATH: path to fasta database(s) for Diamond blastp. To use multiple databases,
                      use "" and a glob pattern Ex. --fastaDBs "path/*.fasta.gz or a list Ex. --fastaDBs path/db1.fasta.gz,path/db2.fasta.gz
     --diamondDBs PATH: path to diamond (.dmnd) database(s) for Diamond blastp. Can be used with or instead of '--fastaDBs'
     --hmmProfiles: in step 1, path to hmm profiles. Ex. --hmmProfiles "path/*.hmm.gz" or --hmmProfiles path/Pfam.hmm.gz,path/Kegg.hmm.gz
     --metaeuk_db: in step 1, database used to predict eukaryotic genes with Metaeuk. If empty, do not run Metaeuk
     --gtdbtkDB: in step 1, databse gtdb used for gtdb-tk. If empty, do not run gtdb-tk
     --database_path: in step 1, path to directory where to store diamond databases (default 'database')
"""

if( params.help ) {

log.info info
    exit 0
}

log.info info


workflow METAGENOMICS_WF {

     if (!params.outdir) {
          exit 1, "Missing parameter 'outdir'. Please provide an output directory using --outdir <path>"
     }
     
     if (!params.step2) {

          if (params.longReads == '' && params.shortReads == '') {
               exit 1, "Either 'longReads' or 'shortReads' is required. Please provide at least one using --longReads <path> or --shortReads <path>. Provide both for hybrid assembly."
          }
          if (!params.skipKraken && params.krakenDB == '') {
               exit 1,  "Missing parameter 'krakenDB'. Please provide a kraken database using --krakenDB <path> or skip Kraken using --skipKraken"
          }


          if (params.onlyKraken) {
          KRAKEN_ONLY()

          } else {
               SETUP_WF()
               if(!params.skipQC) {
                    QC_WF(SETUP_WF.out.ch_long_reads, SETUP_WF.out.ch_short_reads)
                    long_reads = QC_WF.out.long_reads
                    short_reads = QC_WF.out.short_reads
               } else {
                    long_reads = Channel.fromPath(SETUP_WF.out.ch_long_reads)
                    short_reads = Channel.fromPath(SETUP_WF.out.ch_short_reads)
               }
               ASSEMBLY_WF(long_reads, short_reads)       
               ANNOTATION_WF(ASSEMBLY_WF.out.assembly, ASSEMBLY_WF.out.sorted_bam, ASSEMBLY_WF.out.read_type, SETUP_WF.out.diamond_db)

               if (!params.skipKraken) {
                    KRAKEN(long_reads, short_reads)
               }
          }
     } else {
          GROUP_WF()
     }

}

workflow {

    METAGENOMICS_WF()
}