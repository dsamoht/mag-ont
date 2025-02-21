process CHECKM {

    if (workflow.containerEngine == 'singularity') {
        container = params.checkm_singularity
    } else {
        container = params.checkm_docker
    }
    
    publishDir "${params.outdir}/checkm", mode: 'copy'

    input:
    path(dasBins, stageAs: "input_bins/*")

    output:
    path("checkm_qa.tsv"), emit: checkm_stats, optional: true

    script:
    """
    checkm lineage_wf -t ${task.cpus} -x fa --tab_table -f checkm_qa.tsv input_bins/ .
    """
}