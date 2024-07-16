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
                                meta.name = params.sampleName
                            } else {
                                meta.name           = id
                            }
                            return [ meta, read ]
                    }
    } else {
        ch_short_reads = params.shortReads
    }

    if(params.fastaDBs != '') {
        fastaDBsList = params.fastaDBs.split(',') as List
        fasta_db_ch = Channel
            .fromPath(fastaDBsList)
            .map { db ->
                    def name = db.getName().split('.fasta')[0]
                    return [name, db]
            }
        DIAMOND_MAKEDB(fasta_db_ch)
        fasta_diam_ch = DIAMOND_MAKEDB.out.diamond_db
    } else {
        fasta_diam_ch = Channel.empty()
    }

    if(params.diamondDBs != '') {
        diamondDBsList = params.diamondDBs.split(',') as List
        diamond_db_ch = Channel
            .fromPath(diamondDBsList)
            .map { db ->
                    def name = db.getName().split('.dmnd')[0]
                    return [name, db]
            }
    } else {
        diamond_db_ch = Channel.empty()
    }
    diamond_db_ch = diamond_db_ch.concat(fasta_diam_ch)

    emit:
    diamond_db = diamond_db_ch
    ch_long_reads = ch_long_reads
    ch_short_reads = ch_short_reads

}
