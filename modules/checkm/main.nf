process CHECKM {

    conda "bioconda::checkm-genome=1.2.2"
    if (workflow.containerEngine == 'singularity') {
        container = params.checkm_singularity
    } else {
        container = params.checkm_docker
    }
    
    errorStrategy 'ignore'

    publishDir "${params.outdir}/checkm", mode: 'copy'

    input:
    tuple val(meta), path(dasBins, stageAs: "input_bins/*")

    output:
    tuple val(meta), path("checkm_qa.tsv"), emit: checkmStats, optional: true

    script:
    """
    checkm lineage_wf -t ${task.cpus} -x fa --tab_table -f checkm_qa.tsv input_bins/ .
    """
}