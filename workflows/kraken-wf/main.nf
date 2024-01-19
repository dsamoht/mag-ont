include { BRACKEN                           } from '../../modules/bracken'
include { KRAKEN                            } from '../../modules/kraken'
include { KRAKENTOOLS                       } from '../../modules/krakentools'
include { KRONA                             } from '../../modules/krona'


workflow KRAKEN_WF {
    """
    Run Kraken on set of reads determined by the user
    (`--krakenReads` argument). Paired-end reads must
    merged into a single file.
    """
    
    reads = Channel.fromPath(params.krakenReads)
    KRAKEN(reads, params.krakenDB)
    BRACKEN(KRAKEN.out.krakenOutputFile, params.krakenDB)
    KRAKENTOOLS(BRACKEN.out.brackenOutputForKrona)
    KRONA(KRAKENTOOLS.out)

}
