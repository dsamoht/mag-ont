#!/usr/bin/env nextflow

nextflow.enable.dsl=2

workflow DISPATCH {

    ch_input = Channel
        .fromPath(params.input)
        .ifEmpty { exit 1, "Samplesheet not found: ${params.input}" }
        .splitCsv(header: true)
        .map { row ->
            def required = [
                'sample_id',
                'group',
                'assembly_fasta',
                'long_reads',
                'short_reads_1',
                'short_reads_2'
            ]

            required.each { col ->
                if (!row.containsKey(col)) {
                    exit 1, "Samplesheet is missing required column: '${col}'"
                }
            }

            if (!row.sample_id || !row.group) {
                exit 1, "Samplesheet row has empty sample_id or group"
            }

            def assembly     = row.assembly_fasta ? file(row.assembly_fasta, checkIfExists: true) : false
            def long_reads   = row.long_reads     ? file(row.long_reads, checkIfExists: true)     : false
            def short_reads1 = row.short_reads_1  ? file(row.short_reads_1, checkIfExists: true)  : false
            def short_reads2 = row.short_reads_2  ? file(row.short_reads_2, checkIfExists: true)  : false

            return [
                sample_id : row.sample_id,
                group  : row.group,
                assembly : assembly,
                long_reads : long_reads,
                sr1 : short_reads1,
                sr2 : short_reads2
            ]
        }
    .view()

    ch_grouped = ch_input
        .map { row -> [ row.group, row ] }
        .groupTuple(by: 0)

    // Validate sample sheet logic
    ch_grouped.map { group, rows ->

        def assemblies = rows.collect { it.assembly }.findAll { it }
        def long_reads = rows.collect { it.long_reads }.findAll { it }
        def short_reads = rows.collect { [ it.sr1, it.sr2 ] }
                               .flatten()
                               .findAll { it }

        def sample_ids = rows.collect { it.sample_id }

        if (assemblies.size() > 1) {
            exit 1, "Group '${group}' contains multiple assemblies — only one is allowed"
        }

        if (!assemblies && !long_reads) {
            exit 1, "Group '${group}' has no assembly and no long reads to assemble"
        }

        // Determine if assembly is provided or not
        def assembly_source
        def assembly_file

        if (assemblies) {
            assembly_source = 'provided'
            assembly_file   = assemblies[0]
        } else {
            assembly_source = 'to_be_assembled'
            assembly_file   = 'to_be_assembled'
        }

        // Determine binning strategy
        def reads_for_binning
        if (short_reads) {
            reads_for_binning = 'short_reads'
        } else if (long_reads) {
            reads_for_binning = 'long_reads'
        } else {
            exit 1, "Group '${group}' has an assembly but no reads for binning"
        }
    }

    emit:
    ch_input = ch_input
}
