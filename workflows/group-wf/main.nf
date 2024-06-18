include {CONCATENATE_FILES                  } from '../../modules/concatenate_files'
include {CDHIT                              } from '../../modules/cdhit/cdhit'

workflow GROUP_WF {

    genes_files = channel.fromPath(params.step2_inputDir + "/**.faa")
    annot_files = channel.fromPath(params.step2_inputDir + "/**genes_annot_summary.tsv")
    abund_files = channel.fromPath(params.step2_inputDir + "/**genes_abundance.tsv")
    CONCATENATE_FILES(genes_files, annot_files, abund_files)

    CDHIT(CONCATENATE_FILES.out.genesConcat)

}