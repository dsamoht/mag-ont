include { FLYE   } from '../../modules/flye'
include { MEDAKA } from '../../modules/medaka'

workflow LONGREAD_ASSEMBLY {
    take:
    ch_long_reads // [val(meta), path(fastq)] (mandatory)

    main:
    ch_assembled_contigs = channel.empty()
    ch_versions = channel.empty()

    FLYE(ch_long_reads)
    ch_versions = ch_versions.mix(FLYE.out.versions)

    ch_flye_assemblies = FLYE.out.fasta
    ch_assembled_contigs = ch_assembled_contigs.mix(ch_flye_assemblies)

    if (!params.skip_medaka) {
    
        MEDAKA(
            ch_long_reads,
            ch_flye_assemblies
        )
        ch_assembled_contigs = ch_assembled_contigs.mix(MEDAKA.out.consensus)
        ch_versions = ch_versions.mix(MEDAKA.out.versions)
    }

    emit:
    assembled_contigs = ch_assembled_contigs
    versions          = ch_versions
}