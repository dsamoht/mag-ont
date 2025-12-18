process GTDBTK {

    if (workflow.containerEngine == 'singularity') {
        container = params.gtdbtk_singularity
    } else {
        container = params.gtdbtk_docker
    }
    
    publishDir "${params.outdir}/gtdbtk", mode: 'copy'

    input:
    path "bins/*"
    path gtdbtk_db

    output:
    path("gtdbtk.*.summary.tsv"), emit: summary

    script:
    """
    export GTDBTK_DATA_PATH=${gtdbtk_db}
    gtdbtk classify_wf --genome_dir bins --out_dir . --skip_ani_screen --extension .fa --cpus ${task.cpus}
    """
}