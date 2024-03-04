include { BEDTOOLS                          } from '../../modules/bedtools' 
//include { CHECKM                            } from '../../modules/checkm'
//include { COLLECT                           } from '../../modules/collect'
include { DASTOOL                           } from '../../modules/dastool'
include { DASTOOL_CONTIG2BIN as METABAT_C2B } from '../../modules/dastool_contig2bin'
include { DASTOOL_CONTIG2BIN as MAXBIN_C2B  } from '../../modules/dastool_contig2bin'
include { FEATURECOUNTS                     } from '../../modules/featurecounts'
//include { GTDBTK                            } from '../../modules/gtdbtk'
include { MAXBIN                            } from '../../modules/maxbin'
include { MAXBIN_ADJUST_EXT                 } from '../../modules/maxbin_adjust_ext'
include { METABAT                           } from '../../modules/metabat'
include { PRODIGAL                          } from '../../modules/prodigal'
include { SEQKIT                            } from '../../modules/seqkit'
include { TIARA                             } from '../../modules/tiara/tiara_tiara'
include { TIARA_SPLIT_BY_DOMAIN             } from '../../modules/tiara/tiara_split_by_domain'
include { METAEUK_EASY_PREDICT              } from '../../modules/metaeuk/metaeuk_easy_predict'

workflow ANNOTATION_WF {

    take:
    assembly
    sorted_bam
    
    main:
    TIARA(assembly)
    TIARA_SPLIT_BY_DOMAIN(TIARA.out, assembly)
    PRODIGAL(TIARA_SPLIT_BY_DOMAIN.out.bac_contigs)
    METAEUK_EASY_PREDICT(TIARA_SPLIT_BY_DOMAIN.out.euk_contigs)

    FEATURECOUNTS(PRODIGAL.out.genesGff, sorted_bam)

    METABAT(assembly, sorted_bam)
    MAXBIN(assembly, METABAT.out.metabatDepth)
    MAXBIN_ADJUST_EXT(MAXBIN.out.maxbinBins)
    METABAT_C2B(METABAT.out.metabatBins, "metabat")
    MAXBIN_C2B(MAXBIN_ADJUST_EXT.out.renamed_maxbinBins, "maxbin")
        
    contig2bin_ch = METABAT_C2B.out.contigs2bins.
        mix(MAXBIN_C2B.out.contigs2bins).
        collect()

    DASTOOL(assembly, contig2bin_ch)
    
    SEQKIT(DASTOOL.out.dasBins)
    //CHECKM(DASTOOL.out.dasBins)
    //GTDBTK(DASTOOL.out.dasBins, params.gtdbtkDB)
    //COLLECT(SEQKIT.out, CHECKM.out, GTDBTK.out)

}
