include { DIAMOND_MAKEDB } from '../../modules/diamond/diamond_makedb'


workflow SETUP_WF {

    if(params.longReads != '') {
        ch_long_reads = Channel
            .fromPath(params.longReads)
            .map { read ->
                        def meta = [:]
                        if (params.sampleName != '') {
                            meta.name = params.sampleName
                        } else {
                            meta.name           = read.getName().tokenize('.')[0]
                        }
                        return [ meta, read ]
                }
    } else {
        ch_long_reads = params.longReads
    }
    

    if(params.shortReads != '') {
        ch_short_reads = Channel
                .fromFilePairs(params.shortReads)
                .map { id, read ->
                            def meta = [:]
                            if (params.sampleName != '') {
                                meta.name = params.sampleName + '_sr'
                            } else {
                                meta.name           = id
                            }
                            return [ meta, read ]
                    }
    } else {
        ch_short_reads = params.shortReads
    }

    fasta_db_ch = Channel
            .fromPath(params.fastaDBs)
            .map { db ->
                    def name = db.getName().split('.fasta')[0]
                    return [name, db]
            }
    DIAMOND_MAKEDB(fasta_db_ch)

    emit:
    diamond_db = DIAMOND_MAKEDB.out.diamond_db
    ch_long_reads = ch_long_reads
    ch_short_reads = ch_short_reads

}
