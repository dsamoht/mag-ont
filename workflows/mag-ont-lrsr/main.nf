include { BRACKEN                       } from '../../modules/bracken'
include { BWA as BWA_PRE                } from '../../modules/bwa'
include { BWA as BWA_POST               } from '../../modules/bwa'
include { CHECKM                        } from '../../modules/checkm'
include { DASTOOL                       } from '../../modules/dastool'
include { FLYE                          } from '../../modules/flye'
include { KRAKEN                        } from '../../modules/kraken'
include { KRAKENTOOLS                   } from '../../modules/krakentools'
include { KRONA                         } from '../../modules/krona'
include { MAXBIN                        } from '../../modules/maxbin'
include { MAXBIN_ADJUST_EXT             } from '../../modules/maxbin_adjust_ext'
include { MEDAKA                        } from '../../modules/medaka'
include { METABAT                       } from '../../modules/metabat'
include { MINIMAP                       } from '../../modules/minimap'
include { POLYPOLISH                    } from '../../modules/polypolish'
include { PRODIGAL                      } from '../../modules/prodigal'
include { SAMTOOLS as SAMTOOLS_POST_FWD } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_POST_REV } from '../../modules/samtools'
include { SAMTOOLS as SAMTOOLS_POST_LR  } from '../../modules/samtools'


workflow MAG_ONT_LRSR {

    reads = Channel.fromPath(params.reads)
    paired_reads = Channel.fromFilePairs(params.paired_reads)
    KRAKEN(reads, params.kraken_db)
    BRACKEN(KRAKEN.out, params.kraken_db)
    KRAKENTOOLS(BRACKEN.out.brackenOutputForKrona)
    KRONA(KRAKENTOOLS.out)
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
    bam_ch = SAMTOOLS.out.mix(SAMTOOLS_POST_FWD.out, SAMTOOLS_POST_REV)
    METABAT(POLYPOLISH.out, bam_ch)
    MAXBIN(POLYPOLISH.out, METABAT.out.metabatDepth)
    MAXBIN_ADJUST_EXT(MAXBIN.out.maxbinBins)
    bins_ch = METABAT.out.metabatBins.mix(MAXBIN_ADJUST_EXT.out.renamed_maxbinBins)
    DASTOOL(bins_ch)

}