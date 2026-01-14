include { FLYE   } from '../../modules/flye'
include { MEDAKA } from '../../modules/medaka'


workflow LONGREAD_ASSEMBLY {
    take:
    ch_long_reads // [val(meta), path(fastq)] (mandatory)

    main:
    ch_versions = channel.empty()

    FLYE(ch_long_reads)
    ch_versions = ch_versions.mix(FLYE.out.versions)
    ch_flye_assembly = FLYE.out.fasta

    if (!params.skip_medaka) {
        ch_medaka_input = ch_long_reads.join(ch_flye_assembly)
        MEDAKA(ch_medaka_input)
        ch_versions = ch_versions.mix(MEDAKA.out.versions)
        ch_medaka_assembly = MEDAKA.out.fasta
        ch_assembly = ch_medaka_assembly
         
    } else {
        ch_assembly = ch_flye_assembly
    }

    emit:
    assembly = ch_assembly
    versions = ch_versions

}
