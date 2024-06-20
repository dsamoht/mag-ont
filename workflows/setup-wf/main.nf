include { DIAMOND_MAKEDB } from '../../modules/diamond/diamond_makedb'


workflow SETUP_WF {

    ch_long_reads = Channel
            .fromPath(params.longReads)
            .map { read ->
                        def meta = [:]
                        meta.name           = read.getName().tokenize('.')[0]
                        return [ meta, read ]
                }
    if(params.shortReads != '') {
        ch_short_reads = Channel
                .fromFilePairs(params.shortReads)
                .map { id, read ->
                            def meta = [:]
                            meta.name           = id
                            return [ meta, read ]
                    }
    } else {
        ch_short_reads = params.shortReads
    }

    mibig_fasta = Channel.fromPath(params.mibigDB)
    cog_fasta = Channel.fromPath(params.cogDB)
    DIAMOND_MAKEDB(mibig_fasta, "mibig")
    //DIAMOND_MAKEDB(cog_fasta, "cog")

    emit:
    diamond_db = DIAMOND_MAKEDB.out.diamond_db
    ch_long_reads = ch_long_reads
    ch_short_reads = ch_short_reads

}
