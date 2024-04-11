process KRAKENTOOLS_COMBINEKREPORTS {

    if (workflow.containerEngine == 'singularity') {
        container = params.krakentools_singularity
    } else {
        container = params.krakentools_docker
    }

    errorStrategy 'ignore'
    
    input:
        path kreport

    output:
        path("kraken.report"), emit: reports
    script:
        def new_input = kreport instanceof List ? kreport.first() : kreport
        def state = kreport instanceof List ? kreport.last() : "NOSTATE"
        sample_id = sample_ids instanceof List ? sample_ids.first() : sample_ids
        new_state = "kraken.${task.index}.${sample_id}"
        // n.b where this is used below the files will have been moved, hence new_state
        old_input = "${new_state}/${sample_id}.kreport.txt"
    """
    if [[ "${task.index}" == "1" ]]; then
        mkdir "${state}"
    fi

    cp -r "${state}" "${new_state}" 
    touch "${old_input}"

    workflow-glue combine_kreports_modified \
        -r "${new_input}" "${old_input}" \
        -o "${sample_id}.kreport.txt" --only-combined --no-headers
    mv "${sample_id}.kreport.txt" "${new_state}/${sample_id}.kreport.txt"
    """
}
