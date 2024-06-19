include {CONCATENATE_FILES                  } from '../../modules/concatenate_files'
include {CDHIT                              } from '../../modules/cdhit/cdhit'
include {CLSTR_ANALYSIS                     } from '../../modules/clstr_analysis'

workflow GROUP_WF {

    genes_files = Channel
            .fromPath(params.step2_inputDir + "/**.faa")
            .collect()
            .map { files ->
                        def meta = [:]
                        meta.name           = params.step2_name
                        return [ meta, files ]
                }
    annot_files = Channel
            .fromPath(params.step2_inputDir + "/**genes_annot_summary.tsv")
            .collect()
            .map { files ->
                        def meta = [:]
                        meta.name           = params.step2_name
                        return [ meta, files ]
                }
    abund_files = Channel
            .fromPath(params.step2_inputDir + "/**genes_abundance.tsv")
            .collect()
            .map { files ->
                        def meta = [:]
                        meta.name           = params.step2_name
                        return [ meta, files ]
                }

    CONCATENATE_FILES(genes_files, annot_files, abund_files)
    CDHIT(CONCATENATE_FILES.out.genesConcat)
    CLSTR_ANALYSIS(CDHIT.out.clstr_file, CONCATENATE_FILES.out.genesConcat, CONCATENATE_FILES.out.genesAnnotConcat, CONCATENATE_FILES.out.genesAbundConcat)

}