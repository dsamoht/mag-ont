#!/usr/bin/env nextflow

include { BINNING           } from './workflows/binning'
include { CAT_FASTQ         } from './modules/cat'
include { DISPATCH          } from './workflows/dispatch'
include { LONGREAD_ASSEMBLY } from './workflows/longread_assembly'
include { LONGREAD_QC       } from './workflows/longread_qc'


info = """
                                         _   
 _ __ ___   __ _  __ _        ___  _ __ | |_ 
| '_ ` _ \\ / _` |/ _` |_____ / _ \\| '_ \\| __|
| | | | | | (_| | (_| |_____| (_) | | | | |_ 
|_| |_| |_|\\__,_|\\__, |      \\___/|_| |_|\\__|
                 |___/                       

Automation of metagenome assembly and binning
with support for Oxford Nanopore reads
     
     Github: https://github.com/dsamoht/mag-ont
     Version: v1.1.0

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Usage:
     nextflow run main.nf -profile local,docker --input FILE --outdir PATH
Input:
     -profile PROFILE(S): test/local/hpc (select according to available ressources), apptainer/docker/singularity (container engine)
     --outdir PATH: path to output directory
     --input FILE: path to input sample sheet (CSV format)
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

     if (!params.input) {
          exit 1, "Missing parameter 'input'. Please provide a sample sheet using --input FILE"
     }
     
     // Validate sample sheet and dispatch sample(s)
     ch_dispatched = DISPATCH().samplesheet

     // Channel of pre-existing assemblies
     ch_input_assembly = ch_dispatched
        .filter { sample -> sample.assembly }
        .map { sample -> [ [ group: sample.group, sample_ids: [sample.sample_id] ], sample.assembly ] }

     // Channel of input short reads
     ch_short_reads_grouped = ch_dispatched
        .filter { sample -> sample.sr1 && sample.sr2 }
        .map { sample -> 
            def meta = [ sample_id:sample.sample_id, group:sample.group ]
            [ sample.group, [ meta, [sample.sr1, sample.sr2] ] ] 
        }
        .groupTuple()

     // Channel of input long reads
     ch_long_reads = ch_dispatched
        .filter { sample -> sample.long_reads }
        .map { sample ->
               [
                    [
                         sample_id    : sample.sample_id,
                         group        : sample.group,
                         has_assembly : sample.assembly ? true : false
                    ],
                    sample.long_reads
               ]
          }
     
     ch_needs_qc = ch_long_reads
        .filter { meta, reads ->
            !params.skip_qc && !meta.has_assembly
        }

     ch_skip_qc = ch_long_reads
        .filter { meta, reads ->
            params.skip_qc || meta.has_assembly
        }

     // Perform long read QC
     ch_qc_long_reads = LONGREAD_QC(ch_needs_qc).long_reads_qc
     ch_long_reads_final = ch_qc_long_reads.mix(ch_skip_qc)

     // Group channels by group
     ch_grouped_reads = ch_long_reads_final
        .map { meta, reads -> [ meta.group, meta, reads ] }
        .groupTuple(by: 0)
        .map { group, metas, reads_list ->
            [ [ group: group, sample_ids: metas.sample_id ], reads_list ]
        }

     // Concatenate reads for each group if the group contains multiple samples (for co-assembly)
     ch_qc_reads_to_assembly = CAT_FASTQ(ch_grouped_reads).reads
     
     // Long read assembly
     ch_generated_assembly = LONGREAD_ASSEMBLY(ch_qc_reads_to_assembly).assembly
     ch_assembly = ch_generated_assembly.mix(ch_input_assembly)

     // Re-group long reads for the join (carrying metadata)
     ch_long_reads_grouped = ch_long_reads_final
          .map { meta, reads -> [ meta.group, [ meta, reads ] ] }
          .groupTuple()

    ch_binning_input = ch_assembly
          .map { meta, assembly -> [ meta.group, meta, assembly ] }
          .join(ch_long_reads_grouped, remainder: true)
          .join(ch_short_reads_grouped, remainder: true)
          .map { it ->
               def group_id    = it[0]
               def meta        = it[1]
               def assembly    = it[2]
               def long_reads  = it[3] ?: []
               def short_reads = it[4] ?: []
               
               // Consolidate everything into the meta object
               def new_meta = meta + [
                    group: group_id,
                    strategy: short_reads.size() > 0 ? 'short' : 'long',
                    long_reads: long_reads,
                    short_reads: short_reads
               ]

               return [ new_meta, assembly ]
          }

     BINNING(ch_binning_input)

}

process DOWNLOAD_IMAGE {

    tag "${container_url}"
    container "${container_url}"

    input:
    val container_url

    script:
    """
    echo "Successfully pulled ${container_url}"
    """
}

workflow install {
    def container_list = params.findAll { it.key.endsWith('_container') }.values()
    ch_containers = Channel.fromList(container_list)
    DOWNLOAD_IMAGE(ch_containers)
}


workflow {
    if (workflow.profile.contains('install')) {
        install()
    } else {
        MAG_ONT()
    }
}
