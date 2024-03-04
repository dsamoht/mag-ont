process METAEUK_CREATEDB {

    if (workflow.containerEngine == 'singularity') {
        container = params.metaeuk_singularity
    } else {
        container = params.metaeuk_docker
    }
    output:
    path ""

    script:
    """
    metaeuk createdb ${params.metaeuk_db} ... <i:fastaFileN[.gz|.bz2]>|<i:stdin> <o:sequenceDB> [options]
    metaeuk createdb /Users/thomas/Desktop/ ${params.metaeuk_db} --dbtype 1
    """
}