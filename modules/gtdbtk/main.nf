process GTDBTK {

    if (workflow.containerEngine == 'singularity') {
        container = params.gtdbtk_singularity
    } else {
        container = params.gtdbtk_docker
    }

    input:
    path "bins/*"

    output:
    path "gtdbtk.*.summary.tsv", emit: summary

    script:
    """
    gtdbtk classify_wf --genome_dir bins --out_dir . --skip_ani_screen --extension .fa --cpus ${task.cpus}
    """
}