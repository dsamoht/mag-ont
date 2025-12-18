include { CHOPPER                  } from '../../modules/chopper'
include { PORECHOP_ABI             } from '../../modules/porechop_abi'
include { NANOPLOT as NANOPLOT_QC  } from '../../modules/nanoplot'
include { NANOPLOT as NANOPLOT_RAW } from '../../modules/nanoplot'


workflow LONGREAD_QC {

    take:
    ch_raw_long_reads

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()
    ch_raw_long_reads = channel.empty()

    // Access indiviudal long reads file w/o losing metadata
    ch_raw_long_reads = ch_dispatched
        .flatMap { meta, data ->
            [ data.sample_ids, data.long_reads ]
                .transpose()
                .collect { sample_id, lr_file ->
                [ [group_id: meta.group_id, sample_id: sample_id], lr_file ]
            }
        }

    if (! params.skip_qc ) {
                
            NANOPLOT_RAW(ch_raw_long_reads)
            ch_versions = ch_versions.mix(NANOPLOT_RAW.out.versions)

            PORECHOP_ABI(ch_raw_long_reads)
            ch_versions = ch_versions.mix(PORECHOP_ABI.out.versions)
            ch_long_reads_qc = PORECHOP_ABI.out.reads
            ch_multiqc_files = ch_multiqc_files.mix(PORECHOP_ABI.out.log)

            CHOPPER(ch_long_reads_qc)
            ch_versions = ch_versions.mix(CHOPPER.out.versions)
            ch_long_reads_qc = CHOPPER.out.fastq

            NANOPLOT_QC(ch_long_reads_qc)
            ch_versions = ch_versions.mix(NANOPLOT_QC.out.versions)
    } else {
        ch_long_reads_qc = ch_raw_long_reads
      }

    ch_qc_dispatch = ch_dispatched
        .map { meta, data -> [ meta.group_id, meta, data ] }
        .combine(
            ch_long_reads_qc.map { meta, qc_file -> [ meta.group_id, meta.sample_id, qc_file ] },
            by: 0
        )
        .view()
        //.map { group_id, meta, data, sample_id, qc_file -> [ group_id, sample_id, qc_file ] }
        //.groupTuple(by: 0)
        //.map { group_id, sample_ids, qc_files ->
        //    def original_meta = ch_dispatched.filter { m, d -> m.group_id == group_id }.map { m, d -> [m, d] }.first()
        //    [original_meta[0], original_meta[1] + [qc_reads: qc_files]]
        //}
        //.view()

    //emit:
    //dispatch      = ch_qc_dispatch
    //versions      = ch_versions
    //multiqc_files = ch_multiqc_files

}
