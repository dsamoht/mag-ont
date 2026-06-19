#!/usr/bin/env nextflow

include { BINNING           } from './workflows/binning'
include { CAT_FASTQ         } from './modules/cat'
include { DISPATCH          } from './workflows/dispatch'
include { LONGREAD_ASSEMBLY } from './workflows/longread_assembly'
include { LONGREAD_QC       } from './workflows/longread_qc'
include { PYRODIGAL         } from './modules/pyrodigal'


def helpMessage() {
    log.info """
                                         _   
 _ __ ___   __ _  __ _        ___  _ __ | |_ 
| '_ ` _ \\ / _` |/ _` |_____ / _ \\| '_ \\| __|
| | | | | | (_| | (_| |_____| (_) | | | | |_ 
|_| |_| |_|\\__,_|\\__, |      \\___/|_| |_|\\__|
                 |___/                       

Automation of metagenome assembly and binning
with support for nanopore reads
     
     Github: https://github.com/dsamoht/mag-ont
     Version: v1.2.3

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Usage:
     nextflow run main.nf -profile base,docker --input FILE --outdir PATH
Input:
     -profile : comma-separated list of profile(s) to use
          test : 1 cpu (test installation)
          base : 8 cpus (run on a local machine (adjust conf/base.config for more cpus))
          drac : varying number of cpus (run with the slurm executor on the Digital Research Alliance of Canada clusters)

          docker      : use docker containers
          singularity : use singularity containers
          apptainer   : use apptainer containers

     --outdir : path to output directory
     --input  : path to input sample sheet (CSV format)
"""
}

workflow MAG_ONT {

     main:
     if (!params.outdir) {
          exit 1, "Missing parameter 'outdir'. Please provide an output directory using --outdir PATH"
     }

     if (!params.input) {
          exit 1, "Missing parameter 'input'. Please provide a sample sheet using --input FILE"
     }
     ch_versions = channel.empty()
     
     // Validate sample sheet and dispatch sample(s)
     ch_dispatched = DISPATCH().samplesheet

     // Channel of pre-existing assemblies
     ch_input_assembly = ch_dispatched
        .filter { sample -> sample.assembly }
        .map { sample -> [ sample.group, sample.sample_id, sample.assembly ] }
        .groupTuple(by: 0)
        .map { group, sample_ids, assemblies -> 
            def meta = [ group: group, sample_ids: sample_ids.unique() ]
            [ meta, assemblies[0] ] 
        }

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
        .filter { meta, _reads ->
            !params.skip_qc && !meta.has_assembly
        }

     ch_skip_qc = ch_long_reads
        .filter { meta, _reads ->
            params.skip_qc || meta.has_assembly
        }

     // Perform long read QC
     ch_qc_long_reads_out = LONGREAD_QC(ch_needs_qc)
     ch_qc_long_reads = ch_qc_long_reads_out.long_reads_qc
     ch_long_reads_final = ch_qc_long_reads.mix(ch_skip_qc)
     ch_versions = ch_versions.mix(ch_qc_long_reads_out.versions)

     // Group channels by group
     ch_grouped_reads = ch_long_reads_final
          .map { meta, reads -> [ meta.group, meta, reads ] }
          .groupTuple(by: 0)
          .map { group, metas, reads_list ->
               def has_assembly = metas.any { it.has_assembly }
               def sorted_reads = reads_list.sort { a, b -> a.toString() <=> b.toString() }
               [ [ group: group, sample_ids: metas.sample_id, has_assembly: has_assembly ], sorted_reads ]
          }

     ch_reads_to_assemble = ch_grouped_reads
          .filter { meta, _reads -> !meta.has_assembly }

     ch_qc_reads_to_assembly = CAT_FASTQ(ch_reads_to_assemble)
          
     ch_generated_assembly_out = LONGREAD_ASSEMBLY(ch_qc_reads_to_assembly)
     ch_versions = ch_versions.mix(ch_generated_assembly_out.versions)
          
     ch_flye_assembly   = ch_generated_assembly_out.assembly
     ch_medaka_assembly = ch_generated_assembly_out.consensus

     ch_flye_medaka_join = ch_flye_assembly
          .join(ch_medaka_assembly, remainder: true)

     // For publishing: both flye and medaka when available, tagged with assembler
     ch_assembly_to_publish = ch_flye_medaka_join
          .flatMap { meta, flye, medaka ->
               def results = [ [ meta + [assembler: 'flye'], flye ] ]
               if (medaka) results << [ meta + [assembler: 'medaka'], medaka ]
               results
          }

     // For binning: medaka if available, otherwise flye
     ch_assembly_for_binning = ch_flye_medaka_join
          .map { meta, flye, medaka -> [ meta, medaka ?: flye ] }
          .mix(ch_input_assembly)

     ch_genes = PYRODIGAL(
          ch_assembly_for_binning.map { meta, assembly -> [ meta.group, assembly ] }
     )

     ch_long_reads_grouped = ch_long_reads_final
          .map { meta, reads -> [ meta.group, [ meta, reads ] ] }
          .groupTuple()

     ch_binning_input = ch_assembly_for_binning
          .map { meta, assembly -> [ meta.group, meta, assembly ] }
          .join(ch_long_reads_grouped, remainder: true)
          .join(ch_short_reads_grouped, remainder: true)
          .join(ch_genes.gff, remainder: true)
          .map { it ->
               def grp         = it[0]
               def meta        = it[1]
               def assembly    = it[2]
               def raw_long    = it[3] ?: [] 
               def raw_short   = it[4] ?: []
               def gff         = it[5] ?: null
               
               def sorted_long  = raw_long.sort  { a, b -> a[0].sample_id <=> b[0].sample_id }
               def sorted_short = raw_short.sort { a, b -> a[0].sample_id <=> b[0].sample_id }

               def new_meta = meta + [
                    group       : grp,
                    strategy    : sorted_short.size() > 0 ? 'short' : 'long',
                    long_reads  : sorted_long,
                    short_reads : sorted_short,
                    gff         : gff
               ]

               return [ new_meta, assembly ]
          }

     BINNING(ch_binning_input)
     ch_versions = ch_versions.mix(BINNING.out.versions)
     ch_versions = ch_versions
          .unique()
          .collectFile(
               name: 'software_versions.yml',
               storeDir: "${params.outdir}/pipeline_info"
          )

     emit:
     versions               = ch_versions
     nanoplot_raw_html      = ch_qc_long_reads_out.nanoplot_raw_html
     nanoplot_qc_html       = ch_qc_long_reads_out.nanoplot_qc_html
     porechop_log           = ch_qc_long_reads_out.porechop_log
     qc_long_reads          = ch_qc_long_reads
     input_assembly         = ch_input_assembly
     assembly               = ch_assembly_to_publish
     pyrodigal_gff          = ch_genes.gff
     pyrodigal_fna          = ch_genes.fna
     pyrodigal_faa          = ch_genes.faa
     bam                    = BINNING.out.bam
     coverm_contig_stats    = BINNING.out.coverm_contig_stats
     coverm_contig_norm     = BINNING.out.coverm_contig_norm
     metabat_bins           = BINNING.out.metabat_bins
     metabat_depth          = BINNING.out.metabat_depth
     maxbin_bins            = BINNING.out.maxbin_bins
     maxbin_abund           = BINNING.out.maxbin_abund
     concoct_bins           = BINNING.out.concoct_bins
     semibin_bins           = BINNING.out.semibin_bins
     dastool_bins           = BINNING.out.dastool_bins
     contig2bin             = BINNING.out.contig2bin
     coverm_genome_stats    = BINNING.out.coverm_genome_stats
     coverm_genome_norm     = BINNING.out.coverm_genome_norm
     checkm_out             = BINNING.out.checkm_out
     gtdbtk_out             = BINNING.out.gtdbtk_out
     mag_summary            = BINNING.out.mag_summary
     final_contig2bin       = BINNING.out.final_contig2bin

}


workflow {

     main:
     if (params.help) {
          helpMessage()
          exit(0, "")
     } else {
          MAG_ONT()
     }

     publish:
     versions               = MAG_ONT.out.versions
     nanoplot_raw_html      = MAG_ONT.out.nanoplot_raw_html
     nanoplot_qc_html       = MAG_ONT.out.nanoplot_qc_html
     porechop_log           = MAG_ONT.out.porechop_log
     qc_long_reads          = MAG_ONT.out.qc_long_reads
     input_assembly         = MAG_ONT.out.input_assembly
     assembly               = MAG_ONT.out.assembly
     pyrodigal_gff          = MAG_ONT.out.pyrodigal_gff
     pyrodigal_fna          = MAG_ONT.out.pyrodigal_fna
     pyrodigal_faa          = MAG_ONT.out.pyrodigal_faa
     bam                    = MAG_ONT.out.bam
     coverm_contig_stats    = MAG_ONT.out.coverm_contig_stats
     coverm_contig_norm     = MAG_ONT.out.coverm_contig_norm
     metabat_bins           = MAG_ONT.out.metabat_bins
     metabat_depth          = MAG_ONT.out.metabat_depth
     maxbin_bins            = MAG_ONT.out.maxbin_bins
     maxbin_abund           = MAG_ONT.out.maxbin_abund
     concoct_bins           = MAG_ONT.out.concoct_bins
     semibin_bins           = MAG_ONT.out.semibin_bins
     dastool_bins           = MAG_ONT.out.dastool_bins
     contig2bin             = MAG_ONT.out.contig2bin
     coverm_genome_stats    = MAG_ONT.out.coverm_genome_stats
     coverm_genome_norm     = MAG_ONT.out.coverm_genome_norm
     checkm_out             = MAG_ONT.out.checkm_out
     gtdbtk_out             = MAG_ONT.out.gtdbtk_out
     mag_summary            = MAG_ONT.out.mag_summary
     final_contig2bin       = MAG_ONT.out.final_contig2bin

}

output {
    qc_long_reads {
        path { meta, _file -> "group_${meta.group}/reads/post_qc" }
        mode "copy"
    }
    nanoplot_raw_html {
        path { meta, _file -> "group_${meta.group}/quality_assessment/nanoplot/raw/${meta.sample_id}" }
        mode "copy"
    }
    nanoplot_qc_html {
        path { meta, _file -> "group_${meta.group}/quality_assessment/nanoplot/post_qc/${meta.sample_id}" }
        mode "copy"
    }
    porechop_log {
        path { meta, _file -> "group_${meta.group}/quality_control/porechop" }
        mode "copy"
    }
    assembly {
        path { meta, _file -> "group_${meta.group}/assembly/${meta.assembler}" }
        mode "copy"
    }
    input_assembly {
        path { meta, _file -> "group_${meta.group}/assembly/provided" }
        mode "copy"
    }
    pyrodigal_gff {
     path { meta, _file -> "group_${meta}/assembly/pyrodigal" }
     mode "copy"
     }
     pyrodigal_fna {
     path { meta, _file -> "group_${meta}/assembly/pyrodigal" }
     mode "copy"
     }
     pyrodigal_faa {
     path { meta, _file -> "group_${meta}/assembly/pyrodigal" }
     mode "copy"
     }
    bam {
        path { meta, _bam, _bai -> "group_${meta.group}/mapping/samtools" }
        mode "copy"
    }
    coverm_contig_stats {
        path { meta, _file -> "group_${meta}/mapping/coverm" }
        mode "copy"
    }
    coverm_contig_norm {
        path { meta, _file -> "group_${meta}/mapping/genes" }
        mode "copy"
    }
    metabat_bins {
        path { meta, _file -> "group_${meta}/binning/metabat" }
        mode "copy"
    }
    metabat_depth {
        path { meta, _file -> "group_${meta}/binning/metabat" }
        mode "copy"
    }
    maxbin_bins {
        path { meta, _file -> "group_${meta}/binning/maxbin" }
        mode "copy"
    }
    maxbin_abund {
        path { meta, _file -> "group_${meta}/binning/maxbin" }
        mode "copy"
    }
    concoct_bins {
        path { meta, _file -> "group_${meta}/binning/concoct" }
        mode "copy"
    }
    semibin_bins {
        path { meta, _file -> "group_${meta}/binning/semibin" }
        mode "copy"
    }
    dastool_bins {
        path { meta, _file -> "group_${meta}/binning/dastool" }
        mode "copy"
    }
    contig2bin {
        path { meta, _file -> "group_${meta}/binning/contig2bin" }
        mode "copy"
    }
    coverm_genome_stats {
        path { meta, _file -> "group_${meta}/binning/coverm" }
        mode "copy"
     }
     coverm_genome_norm {
          path { meta, _file -> "group_${meta}/binning/coverm" }
          mode "copy"
     }
     checkm_out {
        path { meta, _file -> "group_${meta}/binning/checkm" }
        mode "copy"
     }
     gtdbtk_out {
        path { meta, _file -> "group_${meta}/binning/gtdbtk" }
        mode "copy"
     }
     mag_summary {
        path { meta, _file -> "group_${meta}/binning/summary" }
        mode "copy"
     }
     final_contig2bin {
        path { meta, _file -> "group_${meta}/binning/summary" }
        mode "copy"
     }


    versions {
        path "software_versions"
        mode "copy"
    }
}
