process CAT_FASTQ {

    label 'process_single'

    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "docker.io/dsamoht/bio-utils@sha256:f0cad0d32d8d8fac7bb971736f158200cf19b4817dd796bd9d76240a054bacf2"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.merged.fastq.gz"), emit: reads
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def readList = reads instanceof List ? reads.collect { read -> read.toString() } : [reads.toString()]
    // Gzip members concatenate into a valid gzip file, so all-gzipped input is joined as is;
    // as soon as one file is plain FastQ, everything is decompressed and compressed once
    def merge = readList.every { read -> read.endsWith('.gz') }
        ? "cat ${readList.join(' ')}"
        : "gzip -cdf ${readList.join(' ')} | gzip -c"

    """
    ${merge} > ${prefix}.merged.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coreutils: \$(cat --version | head -n1 | sed 's/^cat (GNU coreutils) //')
        gzip: \$(gzip --version | head -n1 | sed 's/^gzip //')
    END_VERSIONS
    """
}
