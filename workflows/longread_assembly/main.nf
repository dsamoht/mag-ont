include { FLYE     } from '../../modules/local/flye'
include { MEDAKA   } from '../../modules/local/medaka'
include { METAMDBG } from '../../modules/local/metamdbg'

workflow LONGREAD_ASSEMBLY {
    take:
    ch_long_reads // [val(meta), path(fastq)] (mandatory)

    main:
    ch_versions  = channel.empty()
    ch_assembly  = channel.empty()
    ch_consensus = channel.empty()

    if (params.assembler == 'flye') {
        FLYE(ch_long_reads)
        ch_versions = ch_versions.mix(FLYE.out.versions.first())
        ch_assembly = FLYE.out.fasta

        if (!params.skip_medaka) {
            ch_medaka_input = ch_long_reads.join(ch_assembly)
            MEDAKA(ch_medaka_input)
            ch_versions  = ch_versions.mix(MEDAKA.out.versions.first())
            ch_consensus = MEDAKA.out.fasta
        }

    } else if (params.assembler == 'metamdbg') {
        METAMDBG(ch_long_reads)
        ch_versions = ch_versions.mix(METAMDBG.out.versions.first())
        ch_assembly = METAMDBG.out.fasta
  
    }

    emit:
    assembly  = ch_assembly
    consensus = ch_consensus
    versions  = ch_versions
}
