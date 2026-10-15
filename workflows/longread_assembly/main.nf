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
    // The assembly that goes on to binning: the Medaka consensus when Medaka runs, the raw
    // assembly otherwise. Medaka polishes every Flye assembly of the run or none, so this is
    // decided once for the run rather than by joining the two channels, a join that could
    // only tell "no consensus" once every group's assembly was done.
    ch_final_assembly = channel.empty()

    if (params.assembler == 'flye') {
        FLYE(ch_long_reads, params.flye_read_type)
        ch_versions = ch_versions.mix(FLYE.out.versions.first())
        ch_assembly = FLYE.out.fasta
        ch_final_assembly = ch_assembly

        // `--skip_medaka` is the one skip flag that defaults to true, so it is also the
        // only one that has to be turned off from the command line. Nextflow passes
        // `--skip_medaka false` through as the string "false", which Groovy reads as true,
        // so the value is parsed rather than tested for truth.
        if (!params.skip_medaka.toString().toBoolean()) {
            ch_medaka_input = ch_long_reads.join(ch_assembly)
            MEDAKA(ch_medaka_input)
            ch_versions  = ch_versions.mix(MEDAKA.out.versions.first())
            ch_consensus = MEDAKA.out.fasta
            ch_final_assembly = ch_consensus
        }

    } else if (params.assembler == 'metamdbg') {
        METAMDBG(ch_long_reads)
        ch_versions = ch_versions.mix(METAMDBG.out.versions.first())
        ch_assembly = METAMDBG.out.fasta
        ch_final_assembly = ch_assembly

    }

    emit:
    assembly       = ch_assembly
    consensus      = ch_consensus
    final_assembly = ch_final_assembly
    versions       = ch_versions
}
