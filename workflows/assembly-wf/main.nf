include { MEGAHIT                                           } from '../../modules/megahit'
include { FLYE as FLYE_LR                                   } from '../../modules/flye'
include { FLYE as FLYE_LRSR                                 } from '../../modules/flye'
include { MEDAKA as MEDAKA_LR                               } from '../../modules/medaka'
include { MEDAKA as MEDAKA_LRSR                             } from '../../modules/medaka'
include { HYBRID_SPADES                                     } from '../../modules/hybrid_spades'
include { BOWTIE                                            } from '../../modules/bowtie'
include { BWA as BWA_SR                                     } from '../../modules/bwa'
include { BWA as BWA_HS                                     } from '../../modules/bwa'
include { BWA as BWA_PRE                                    } from '../../modules/bwa'
include { BWA as BWA_POST                                   } from '../../modules/bwa'
include { SAMTOOLS as SAMTOOLS_SR_POST                      } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_LR                           } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_SRHS_FWD                     } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_SRHS_REV                     } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_LRSR_POST_FWD                } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_LRSR_POST_REV                } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_LRSR_LR                      } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_LRHS                         } from '../../modules/samtools'
include { MINIMAP as MINIMAP_LR                             } from '../../modules/minimap'
include { MINIMAP as MINIMAP_HS                             } from '../../modules/minimap'
include { MINIMAP as MINIMAP_LRSR                           } from '../../modules/minimap'
include { POLYPOLISH                                        } from '../../modules/polypolish'


workflow ASSEMBLY_WF {
    take:
    filt_long_reads

    main:
    if (params.longReads == "" && params.shortReads != "") {
        read_type = "paired"
        short_reads = Channel.fromFilePairs(params.shortReads)
        MEGAHIT(short_reads)
        assembly_channel = MEGAHIT.out
        BOWTIE(MEGAHIT.out, short_reads)
        SAMTOOLS_SR_POST(BOWTIE.out, "short_reads_sam")
        bam_channel = SAMTOOLS_SR_POST.out
    }

    else if (params.longReads != "" && params.shortReads == "") {
        read_type = "long"
        FLYE_LR(filt_long_reads)
        MEDAKA_LR(filt_long_reads, FLYE_LR.out)
        assembly_channel = FLYE_LR.out
        MINIMAP_LR(filt_long_reads, FLYE_LR.out)
        SAMTOOLS_LR(MINIMAP_LR.out, "long_reads_sam")
        bam_channel = SAMTOOLS_LR.out
    }

    else if (params.longReads != "" && params.shortReads != "") {
        read_type = "hybrid"
        short_reads = Channel.fromFilePairs(params.shortReads)

        if (params.hybrid_assembler == "hybridspades") {
            HYBRID_SPADES(filt_long_reads, short_reads)
            assembly_channel = HYBRID_SPADES.out
            MINIMAP_HS(HYBRID_SPADES.out, filt_long_reads)
            SAMTOOLS_LRHS(MINIMAP_HS.out, "lr_sam")
            BWA_HS(HYBRID_SPADES.out, short_reads)
            SAMTOOLS_SRHS_FWD(BWA_HS.out.fwdSam, "fwd_sam")
            SAMTOOLS_SRHS_REV(BWA_HS.out.revSam, "rev_sam")
            
            bam_channel = SAMTOOLS_SRHS_FWD.out.
                mix(SAMTOOLS_SRHS_REV.out).
                collect()
            
        }
        else if (params.hybrid_assembler == "") {
            FLYE_LRSR(filt_long_reads)
            MEDAKA_LRSR(filt_long_reads, FLYE_LRSR.out)
            BWA_PRE(MEDAKA_LRSR.out, short_reads)
            POLYPOLISH(MEDAKA_LRSR.out, BWA_PRE.out.fwdSam, BWA_PRE.out.revSam)
            assembly_channel = POLYPOLISH.out
            MINIMAP_LRSR(POLYPOLISH.out, filt_long_reads)
            SAMTOOLS_LRSR_LR(MINIMAP_LRSR.out, "lrSam")
            BWA_POST(POLYPOLISH.out, short_reads)
            SAMTOOLS_LRSR_POST_FWD(BWA_POST.out.fwdSam, "fwdSam")
            SAMTOOLS_LRSR_POST_REV(BWA_POST.out.revSam, "revSam")
            bam_channel = SAMTOOLS_LRSR_POST_FWD.out.
                mix(SAMTOOLS_LRSR_POST_REV.out).
                collect()
        }
    }

    emit:
    assembly = assembly_channel
    sorted_bam = bam_channel
    read_type = read_type

}
