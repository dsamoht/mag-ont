include { BRACKEN           } from '../../modules/bracken'
include { CHECKM            } from '../../modules/checkm'
include { DASTOOL           } from '../../modules/dastool'
include { FLYE              } from '../../modules/flye'
include { GTDBTK            } from '../../modules/gtdbtk'
include { KRAKEN            } from '../../modules/kraken'
include { KRAKENTOOLS       } from '../../modules/krakentools'
include { KRONA             } from '../../modules/krona'
include { MAXBIN            } from '../../modules/maxbin'
include { MAXBIN_ADJUST_EXT } from '../../modules/maxbin_adjust_ext'
include { MEDAKA            } from '../../modules/medaka'
include { METABAT           } from '../../modules/metabat'
include { MINIMAP           } from '../../modules/minimap'
include { PRODIGAL          } from '../../modules/prodigal'
include { SAMTOOLS          } from '../../modules/samtools'

workflow MAG_ONT_LR {

    reads = Channel.fromPath(params.reads)
    KRAKEN(reads, params.kraken_db)
    BRACKEN(KRAKEN.out, params.kraken_db)
    KRAKENTOOLS(BRACKEN.out.brackenOutputForKrona)
    KRONA(KRAKENTOOLS.out)
    FLYE(reads)
    MEDAKA(reads, FLYE.out)
    PRODIGAL(MEDAKA.out)
    MINIMAP(reads, MEDAKA.out)
    SAMTOOLS(MINIMAP.out)
    METABAT(MEDAKA.out, SAMTOOLS.out)
    SAMTOOLS.out.view()
    MAXBIN(MEDAKA.out, METABAT.out.metabatDepth)
    MAXBIN_ADJUST_EXT(MAXBIN.out.maxbinBins)
    bins_ch = METABAT.out.metabatBins.mix(MAXBIN_ADJUST_EXT.out.renamed_maxbinBins)
    DASTOOL(bins_ch)
    CHECKM(DASTOOL.out.dasBins)
    GTDBTK(DASTOOL.out.dasBins)

}