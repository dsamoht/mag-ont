include {CONCATENATE_FILES                  } from '../../modules/concatenate_files'
include {CDHIT                              } from '../../modules/cdhit/cdhit'
include {CLSTR_ANALYSIS                     } from '../../modules/clstr_analysis'

workflow GROUP_WF {

    genes_files = Channel
            .fromPath(params.step2_inputDir + "/**.faa")
            .collect()
            .map { file ->
                        def meta = [:]
                        meta.name           = "experiment1"
                        return [ meta, file ]
                }
    annot_files = Channel
            .fromPath(params.step2_inputDir + "/**genes_annot_summary.tsv")
            .collect()
            .map { file ->
                        def meta = [:]
                        meta.name           = "experiment1"
                        return [ meta, file ]
                }
    abund_files = Channel
            .fromPath(params.step2_inputDir + "/**genes_abundance.tsv")
            .collect()
            .map { file ->
                        def meta = [:]
                        meta.name           = "experiment1"
                        return [ meta, file ]
                }

    CONCATENATE_FILES(genes_files, annot_files, abund_files)
    CDHIT(CONCATENATE_FILES.out.genesConcat)
    CLSTR_ANALYSIS(CDHIT.out.clstr_file, genes_files, annot_files, abund_files)

}