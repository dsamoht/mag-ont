process KRAKENTOOLS_KRONA {

    conda "bioconda::krakentools=1.2"
    if (workflow.containerEngine == 'singularity') {
        container = params.krakentools_singularity
    } else {
        container = params.krakentools_docker
    }

    errorStrategy 'ignore'

    input:
    tuple val(meta), path(brackenOutputForKrona)

    output:
    tuple val(meta), path('krona.out'), emit: krakentoolsToKrona, optional: true

    script:
    """
    kreport2krona.py -r ${brackenOutputForKrona} -o krona.out --no-intermediate-ranks
    """
}