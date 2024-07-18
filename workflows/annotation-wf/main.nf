include { BEDTOOLS                          } from '../../modules/bedtools' 
include { CHECKM                            } from '../../modules/checkm'
include { CDHIT_CDHIT as CDHIT_2d           } from '../../modules/cdhit/cdhit_cdhit'
include { DASTOOL                           } from '../../modules/dastool'
include { DASTOOL_CONTIG2BIN as METABAT_C2B } from '../../modules/dastool_contig2bin'
include { DASTOOL_CONTIG2BIN as MAXBIN_C2B  } from '../../modules/dastool_contig2bin'
include { DIAMOND_BLASTP                    } from '../../modules/diamond/diamond_blastp'
include { FEATURECOUNTS                     } from '../../modules/featurecounts'
include { FEATURECOUNTS_SUMMARY             } from '../../modules/featurecounts_summary'
include { MMSEQS_CLUSTER                    } from '../../modules/mmseqs/mmseqs_cluster'
include { GTDBTK                            } from '../../modules/gtdbtk'
include { BIN_ANNOTATION                    } from '../../modules/bin_annotation'
include { MAXBIN                            } from '../../modules/maxbin'
include { MAXBIN_ADJUST_EXT                 } from '../../modules/maxbin_adjust_ext'
include { METABAT                           } from '../../modules/metabat'
include { PRODIGAL                          } from '../../modules/prodigal'
include { SEQKIT                            } from '../../modules/seqkit'
include { TIARA                             } from '../../modules/tiara/tiara_tiara'
include { TIARA_SPLIT_BY_DOMAIN             } from '../../modules/tiara/tiara_split_by_domain'
include { METAEUK_EASY_PREDICT              } from '../../modules/metaeuk/metaeuk_easy_predict'
include { METAEUK_MODIFY_GFF                } from '../../modules/metaeuk/metaeuk_modify_gff'
include { HMMER                             } from '../../modules/hmmer'
include { HMMER_SUMMARY                     } from '../../modules/hmmer_summary'
include { PREPARE_STEP2                     } from '../../modules/prepare_step2'
include { CONCATENATE                       } from '../../modules/concatenate'


workflow ANNOTATION_WF {

    take:
    assembly
    sorted_bam
    read_type
    diamond_db
    
    main:
    TIARA(assembly)
    TIARA_SPLIT_BY_DOMAIN(TIARA.out, assembly)
    PRODIGAL(TIARA_SPLIT_BY_DOMAIN.out.bac_contigs)
    genes_pred = PRODIGAL.out.genesFaa.collect()
    bac_gff = PRODIGAL.out.genesGff
    if (params.metaeuk_db != '') {
        METAEUK_EASY_PREDICT(TIARA_SPLIT_BY_DOMAIN.out.euk_contigs, params.metaeuk_db)
        METAEUK_MODIFY_GFF(METAEUK_EASY_PREDICT.out.euk_proteins)
        euk_gff = METAEUK_EASY_PREDICT.out.euk_gff
        genes_bac_euk = PRODIGAL.out.genesFaa.mix(METAEUK_EASY_PREDICT.out.euk_proteins).groupTuple()
        CONCATENATE(genes_bac_euk, "genes_pred.faa")
        genes_pred = CONCATENATE.out.concatFile.collect()
    } else {
        euk_gff = Channel.empty()
    }
    gff_ch = bac_gff.mix(euk_gff).groupTuple()
    FEATURECOUNTS(gff_ch, sorted_bam, read_type)
    FEATURECOUNTS_SUMMARY(FEATURECOUNTS.out.counts)
    if (params.fastaDBs != '' || params.diamondDBs != '') {
        DIAMOND_BLASTP(genes_pred, diamond_db)
        diamond = DIAMOND_BLASTP.out.diamond_result.groupTuple()
    } else {
        diamond = Channel.fromPath("$projectDir/database/NO_FILE")
        diamond = genes_pred.map{ it[0] }.combine(diamond)
    }
    //CDHIT_2d(PRODIGAL.out.genesFaa, params.mibigDB, "mibig")
    METABAT(assembly, sorted_bam)
    MAXBIN(assembly, METABAT.out.metabatDepth)
    MAXBIN_ADJUST_EXT(MAXBIN.out.maxbinBins)
    METABAT_C2B(METABAT.out.metabatBins, "metabat")
    MAXBIN_C2B(MAXBIN_ADJUST_EXT.out.renamed_maxbinBins, "maxbin")

    contig2bin_ch = METABAT_C2B.out.contigs2bins.
        mix(MAXBIN_C2B.out.contigs2bins).
        groupTuple()

    DASTOOL(assembly, contig2bin_ch)
    
    SEQKIT(DASTOOL.out.dasBins)
    CHECKM(DASTOOL.out.dasBins)
    if (params.gtdbtkDB != '') {
        GTDBTK(DASTOOL.out.dasBins, params.gtdbtkDB)
        gtdbtk_summary = GTDBTK.out.summary
    } else {
        gtdbtk_summary = Channel.fromPath("$projectDir/database/NO_FILE")
        gtdbtk_summary = DASTOOL.out.dasBins.map{ it[0] }.combine(gtdbtk_summary)
    }
    BIN_ANNOTATION(contigs2bins = contig2bin_ch, gtdbtk = gtdbtk_summary, seqkitStats = SEQKIT.out.seqkitStats, checkmStats = CHECKM.out.checkmStats)

    if(params.hmmProfiles != '') {
        profilesList = params.hmmProfiles.split(',') as List
        profiles = Channel
                        .fromPath(profilesList)
                        .map {profile -> 
                                def name = profile.getName().split('.hmm')[0]
                                return [name, profile]
                        }
        HMMER(genes = genes_pred, profiles)
        hmmerTable = HMMER.out.hmmerTable.groupTuple()
    } else {
        hmmerTable = Channel.fromPath("empty_table.txt")
        hmmerTable = diamond.map{ it[0] }.combine(hmmerTable)
    }
    HMMER_SUMMARY(hmmerTable = hmmerTable, koList = params.koList, diamond_result = diamond)

    PREPARE_STEP2(PRODIGAL.out.genesFaa, HMMER_SUMMARY.out.hmmerSummary, FEATURECOUNTS_SUMMARY.out.featurecountsSummary)

}
