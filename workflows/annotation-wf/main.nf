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
    genes_bac = PRODIGAL.out.genesFaa.collect()
    bac_gff = PRODIGAL.out.genesGff
    if (params.metaeuk_db != '') {
        METAEUK_EASY_PREDICT(TIARA_SPLIT_BY_DOMAIN.out.euk_contigs, params.metaeuk_db)
        METAEUK_MODIFY_GFF(METAEUK_EASY_PREDICT.out.euk_proteins)
        euk_gff = METAEUK_MODIFY_GFF.out.euk_gff_modif
    } else {
        euk_gff = Channel.empty()
    }
    gff_ch = bac_gff.mix(euk_gff).groupTuple()
    FEATURECOUNTS(gff_ch, sorted_bam, read_type)
    FEATURECOUNTS_SUMMARY(FEATURECOUNTS.out.counts)
    //mibig_path = Channel.fromPath("/Users/thomas/Desktop/mag-ont/mibig_prot_seqs_3.1.fasta")
    //mibig_dmnd_path = Channel.fromPath("/Users/thomas/Desktop/mag-ont/database/mibig.dmnd")
    DIAMOND_BLASTP(genes_bac, diamond_db)
    diamond = DIAMOND_BLASTP.out.diamond_result.groupTuple()
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
        gtdbtk_summary = Channel
            .fromPath("$projectDir/database/NO_FILE")
            .map { read ->
                        def meta = [:]
                        meta.name           = "no_name"
                        return [ meta, read ]
                }
    }
    BIN_ANNOTATION(contigs2bins = contig2bin_ch, gtdbtk = gtdbtk_summary, seqkitStats = SEQKIT.out.seqkitStats, checkmStats = CHECKM.out.checkmStats)

    if(params.profilePfam != '' || params.profileKegg != '') {
        profiles = Channel.of(["pfam", params.profilePfam], ["kegg", params.profileKegg])
        HMMER(genes = genes_bac, profiles.filter{ it.count('') == 0 })
        hmmerTable = HMMER.out[0].groupTuple()
    } else {
        hmmerTable = Channel
            .fromPath("$projectDir/database/NO_FILE")
            .map { read ->
                        def meta = [:]
                        meta.name           = "no_name"
                        return [ meta, read ]
                }
    }
    HMMER_SUMMARY(hmmerTable = hmmerTable, koList = params.koList, diamond_result = diamond)

    PREPARE_STEP2(PRODIGAL.out.genesFaa, HMMER_SUMMARY.out.hmmerSummary, FEATURECOUNTS_SUMMARY.out.featurecountsSummary)

}
