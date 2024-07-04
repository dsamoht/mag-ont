include {CONCATENATE_FILES                  } from '../../modules/concatenate_files'
include {CDHIT                              } from '../../modules/cdhit/cdhit'
include {CLSTR_ANALYSIS                     } from '../../modules/clstr_analysis'

workflow GROUP_WF {

    if(params.step2_sheet != '') {
                results_ch = Channel.fromPath(params.step2_sheet)
                .splitText() {it.split('\t')[1].split('\n')[0]}
                .collect()
                .map { files ->
                        def meta = [:]
                        meta.name           = params.step2_name
                        return [ meta, files ]
                }
    } else {
        exit 1, "An input sheet is required for step 2. Please provide one using --step2_sheet <path>"
    }

    CONCATENATE_FILES(results_ch)
    CDHIT(CONCATENATE_FILES.out.genesConcat)
    gtdbtk_concat = CONCATENATE_FILES.out.gtdbtkConcat.ifEmpty("$projectDir/database/NO_FILE")
    CLSTR_ANALYSIS(CDHIT.out.clstr_file, CONCATENATE_FILES.out.genesConcat, CONCATENATE_FILES.out.genesAnnotConcat, CONCATENATE_FILES.out.genesAbundConcat, gtdbtk_concat)

}