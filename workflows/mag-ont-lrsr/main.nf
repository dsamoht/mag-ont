include { BWA as BWA_PRE                    } from '../../modules/bwa'
include { BWA as BWA_POST                   } from '../../modules/bwa'
include { CHECKM                            } from '../../modules/checkm'
include { COLLECT                           } from '../../modules/collect'
include { DASTOOL                           } from '../../modules/dastool'
include { DASTOOL_CONTIG2BIN as METABAT_C2B } from '../../modules/dastool_contig2bin'
include { DASTOOL_CONTIG2BIN as MAXBIN_C2B  } from '../../modules/dastool_contig2bin'
include { FLYE                              } from '../../modules/flye'
include { GTDBTK                            } from '../../modules/gtdbtk'
include { MAXBIN                            } from '../../modules/maxbin'
include { MAXBIN_ADJUST_EXT                 } from '../../modules/maxbin_adjust_ext'
include { MEDAKA                            } from '../../modules/medaka'
include { METABAT                           } from '../../modules/metabat'
include { MINIMAP                           } from '../../modules/minimap'
include { POLYPOLISH                        } from '../../modules/polypolish'
include { PRODIGAL                          } from '../../modules/prodigal'
include { SAMTOOLS as SAMTOOLS_POST_FWD     } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_POST_REV     } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_POST_LR      } from '../../modules/samtools'
include { SEQKIT                            } from '../../modules/seqkit'
include { TIARA                             } from '../../modules/tiara'


workflow MAG_ONT_LRSR {

    reads = Channel.fromPath(params.reads)
    paired_reads = Channel.fromFilePairs(params.pairedReads)

    FLYE(reads)
    MEDAKA(reads, FLYE.out)
    BWA_PRE(MEDAKA.out, paired_reads)
    POLYPOLISH(MEDAKA.out, BWA_PRE.out.fwdSam, BWA_PRE.out.revSam)
    BWA_POST(POLYPOLISH.out, paired_reads)
    MINIMAP(reads, POLYPOLISH.out)
    SAMTOOLS_POST_LR(MINIMAP.out)
    SAMTOOLS_POST_FWD(BWA_POST.out.fwdSam)
    SAMTOOLS_POST_REV(BWA_POST.out.revSam)
    PRODIGAL(POLYPOLISH.out)
    bam_ch = SAMTOOLS_POST_LR.out.flatten().
        mix(SAMTOOLS_POST_FWD.out.flatten()).
        mix(SAMTOOLS_POST_REV.out.flatten()).
        collect()
    METABAT(POLYPOLISH.out, bam_ch)
    MAXBIN(POLYPOLISH.out, METABAT.out.metabatDepth)
    MAXBIN_ADJUST_EXT(MAXBIN.out.maxbinBins)
    METABAT_C2B(METABAT.out.metabatBins, "metabat")
    MAXBIN_C2B(MAXBIN_ADJUST_EXT.out.renamed_maxbinBins, "maxbin")
        
    contig2bin_ch = METABAT_C2B.out.contigs2bins.
        mix(MAXBIN_C2B.out.contigs2bins).
        collect()

    DASTOOL(POLYPOLISH.out, contig2bin_ch)
    TIARA(POLYPOLISH.out)
    SEQKIT(DASTOOL.out.dasBins)
    CHECKM(DASTOOL.out.dasBins)
    GTDBTK(DASTOOL.out.dasBins, params.gtdbtkDB)
    COLLECT(SEQKIT.out, CHECKM.out, GTDBTK.out)

}
