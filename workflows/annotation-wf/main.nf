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
    METAEUK_EASY_PREDICT(TIARA_SPLIT_BY_DOMAIN.out.euk_contigs, params.metaeuk_db)
    METAEUK_MODIFY_GFF(METAEUK_EASY_PREDICT.out.euk_proteins)
    FEATURECOUNTS(PRODIGAL.out.genesGff, METAEUK_MODIFY_GFF.out, sorted_bam, read_type)
    FEATURECOUNTS_SUMMARY(FEATURECOUNTS.out.counts)
    //mibig_path = Channel.fromPath("/Users/thomas/Desktop/mag-ont/mibig_prot_seqs_3.1.fasta")
    //mibig_dmnd_path = Channel.fromPath("/Users/thomas/Desktop/mag-ont/database/mibig.dmnd")
    DIAMOND_BLASTP(genes_bac, diamond_db)
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
    GTDBTK(DASTOOL.out.dasBins, params.gtdbtkDB)
    BIN_ANNOTATION(contigs2bins = contig2bin_ch, gtdbtk = GTDBTK.out.summary, seqkitStats = SEQKIT.out.seqkitStats, checkmStats = CHECKM.out.checkmStats)

    if(params.profilePfam != '' || params.profileKegg != '') {
        profiles = Channel.of(["pfam", params.profilePfam], ["kegg", params.profileKegg])
        HMMER(genes = genes_bac, profiles.filter{ it.count('') == 0 })
        diamond = DIAMOND_BLASTP.out.diamond_result.groupTuple()
        HMMER_SUMMARY(hmmerDomTable = HMMER.out[1].groupTuple(), koList = params.koList, diamond_result = diamond)
    }

    if(params.step2_sheet == '') {
                step2_sheet_ch = Channel.fromPath(params.step2_sheet + 'step2_input_sheet.tsv')
        } else {
                step2_sheet_ch = Channel.fromPath(params.step2_sheet)
        }
    PREPARE_STEP2(PRODIGAL.out.genesFaa, HMMER_SUMMARY.out.hmmerSummary, FEATURECOUNTS_SUMMARY.out.featurecountsSummary, step2_sheet_ch)

}
