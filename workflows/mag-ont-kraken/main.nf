include { BRACKEN                           } from '../../modules/bracken'
include { KRAKEN                            } from '../../modules/kraken'
include { KRAKENTOOLS                       } from '../../modules/krakentools'
include { KRONA                             } from '../../modules/krona'


workflow MAG_ONT_KRAKEN {

    reads = Channel.fromPath(params.reads)
    KRAKEN(reads, params.krakenDB)
    BRACKEN(KRAKEN.out.krakenOutputFile, params.krakenDB)
    KRAKENTOOLS(BRACKEN.out.brackenOutputForKrona)
    KRONA(KRAKENTOOLS.out)

}
