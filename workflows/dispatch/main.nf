#!/usr/bin/env nextflow

nextflow.enable.dsl=2

workflow DISPATCH {

    def samplesheet_file = file(params.input, checkIfExists: true)
    def lines = samplesheet_file.text.readLines()
    lines.eachWithIndex { line, idx ->
        def columns = line.split(',', -1)
        if (columns.size() != 6) {
            def line_num = idx
            exit 1, "sample sheet error : ${columns.size()} field(s) found at line ${line_num}; exactly 6 fields (5 commas) are expected."
        }
    }

    ch_samplesheet = Channel
        .fromPath(samplesheet_file)
        .ifEmpty { exit 1, "sample sheet not found: `${params.input}`" }
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
                    exit 1, "sample sheet is missing required column: `${col}`"
                }
            }

            if (!row.sample_id || !row.group) {
                exit 1, "sample sheet row has empty `sample_id` or `group`"
            }

            if (!row.assembly_fasta && !row.long_reads) {
                exit 1, "sample sheet row `${row}` has empty `long_reads` and empty `assembly_fasta`"
            }
            
            def has_sr1 = row.short_reads_1 ? true : false
            def has_sr2 = row.short_reads_2 ? true : false
            if (has_sr1 != has_sr2) {
                exit 1, "sample `${row.sample_id}` has unpaired short reads - both `short_reads_1` and `short_reads_2` are required"
            }

            def assembly     = row.assembly_fasta ? file(row.assembly_fasta, checkIfExists: true) : false
            def long_reads   = row.long_reads     ? file(row.long_reads, checkIfExists: true)     : false
            def short_reads1 = row.short_reads_1  ? file(row.short_reads_1, checkIfExists: true)  : false
            def short_reads2 = row.short_reads_2  ? file(row.short_reads_2, checkIfExists: true)  : false

            return [
                sample_id     : row.sample_id,
                group         : row.group,
                assembly      : assembly,
                assembly_path : row.assembly_fasta ?: '',
                long_reads    : long_reads,
                sr1           : short_reads1,
                sr2           : short_reads2
            ]
        }

    // Validate sample sheet grouping logic
    ch_validate = ch_samplesheet
        .map { row -> [ row.group, row ] }
        .groupTuple(by: 0)
        .map { group, rows ->
            def sample_ids  = rows.collect { it.sample_id }.findAll()
            def long_reads  = rows.collect { it.long_reads }.findAll()
            def assemblies  = rows.collect { it.assembly }.findAll()
            def assembly_paths = rows.collect { it.assembly_path }.findAll()
            def short_reads = rows.collect { [ it.sr1, it.sr2 ] }.flatten().findAll()

            if (assemblies.isEmpty() && long_reads.isEmpty()) {
                exit 1, "group '${group}' has no assembly and no long reads to assemble"
            }
            
            // Check for shared read files within the group
            def path_to_samples = [:]
            rows.each { r ->
                [r.long_reads, r.sr1, r.sr2].each { f ->
                    if (f) {
                        def p = f.toString()
                        if (!path_to_samples[p]) path_to_samples[p] = []
                        path_to_samples[p] << r.sample_id
                    }
                }
            }
            path_to_samples.each { path, ids ->
                if (ids.unique().size() > 1) {
                    exit 1, "group '${group}' error: read file '${path}' is shared by multiple samples: ${ids.unique().join(', ')}"
                }
            }

            if (!assemblies.isEmpty()) {
                def unique_assembly_path = assembly_paths.unique()
                
                if (unique_assembly_path.size() > 1) {
                    exit 1, "group '${group}' contains multiple different assemblies: ${unique_assembly_path.join(', ')} — only one unique assembly is allowed per group"
                }
            
                def samples_with_assembly = rows.findAll { it.assembly_path }
                def samples_without_assembly = rows.findAll { !it.assembly_path }
                
                if (!samples_without_assembly.isEmpty()) {
                    def missing_samples = samples_without_assembly.collect { it.sample_id }.join(', ')
                    exit 1, "group '${group}' has inconsistent assembly assignment — some samples have assembly '${unique_assembly_path[0]}' but these samples are missing it: ${missing_samples}. All samples in a group must share the same assembly."
                }
                
                if (long_reads.isEmpty() && short_reads.isEmpty()) {
                    exit 1, "group '${group}' has assembly '${unique_assembly_path[0]}' but no reads (long or short) for binning"
                }
            }

            if (rows.size() > 1) {
                def samples_with_only_long = rows.findAll { it.long_reads && !it.sr1 }
                def samples_with_only_short = rows.findAll { !it.long_reads && it.sr1 && it.sr2 }
                
                def has_only_long = !samples_with_only_long.isEmpty()
                def has_only_short = !samples_with_only_short.isEmpty()
                
                if (has_only_long && has_only_short) {
                    def long_samples = samples_with_only_long.collect { it.sample_id }.join(', ')
                    def short_samples = samples_with_only_short.collect { it.sample_id }.join(', ')
                    exit 1, "group '${group}' mixes read types across samples. Samples with long reads: [${long_samples}]. Samples with paired-end reads: [${short_samples}]."
                }
            }

        }
        .collect()      

    emit:
    samplesheet = ch_samplesheet
    validate    = ch_validate

}
