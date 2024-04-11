process KRAKENTOOLS_KRONA {

    if (workflow.containerEngine == 'singularity') {
        container = params.krakentools_singularity
    } else {
        container = params.krakentools_docker
    }

    errorStrategy 'ignore'

    input:
    path brackenOutputForKrona

    output:
    path 'krona.out', emit: krakentoolsToKrona, optional: true

    script:
    """
    kreport2krona.py -r ${brackenOutputForKrona} -o krona.out --no-intermediate-ranks
    """
}