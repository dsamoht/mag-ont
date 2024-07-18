process CONCATENATE {

    input:
    tuple val(meta), path(files)
    val filename

    output:
    tuple val(meta), path(filename), emit: concatFile

    script:
    """
    cat ${files} > ${filename}
    """
}