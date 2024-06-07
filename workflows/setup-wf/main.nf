include { DIAMOND_MAKEDB } from '../../modules/diamond/diamond_makedb'


workflow SETUP_WF {

    mibig_fasta = Channel.fromPath(params.mibigDB)
    cog_fasta = Channel.fromPath(params.cogDB)
    DIAMOND_MAKEDB(mibig_fasta, "mibig")
    DIAMOND_MAKEDB(cog_fasta, "cog")

    emit:
    diamond_db = DIAMOND_MAKEDB.out.diamond_db

}
