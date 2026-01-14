process FLYE {

    tag "group_${meta.group}"

    container params.flye_container

    errorStrategy 'finish'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fasta") , emit: fasta
    tuple val(meta), path("*.gfa")   , emit: gfa
    tuple val(meta), path("*.txt")   , emit: txt
    tuple val(meta), path("*.log")   , emit: log
    tuple val(meta), path("*.json")  , emit: json
    path "versions.yml"              , emit: versions

    script:
    """
    flye \
        --meta \
        --nano-hq ${reads} \
        --threads ${task.cpus} \
        --out-dir .
    
    mv assembly.fasta ${meta.group}.assembly.fasta
    mv assembly_graph.gfa ${meta.group}.assembly_graph.gfa
    mv assembly_info.txt ${meta.group}.assembly_info.txt
    mv flye.log ${meta.group}.flye.log
    mv params.json ${meta.group}.params.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$( flye --version )
    END_VERSIONS
    """
}
