//
// Subworkflow with functionality specific to the dsamoht/mag-ont pipeline
//

include { paramsHelp         } from 'plugin/nf-schema'
include { paramsSummaryLog   } from 'plugin/nf-schema'
include { samplesheetToList  } from 'plugin/nf-schema'
include { validateParameters } from 'plugin/nf-schema'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO INITIALISE PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_INITIALISATION {

    take:
    validate_params // boolean: validate parameters against nextflow_schema.json
    input           // string : path to the sample sheet
    help            // boolean or string: display the help message
    help_full       // boolean: display the full help message
    show_hidden     // boolean: display hidden parameters in the help message

    main:

    //
    // Print the help message built from nextflow_schema.json and exit
    //
    if (help || help_full) {
        log.info(paramsHelp(
            [
                command   : "nextflow run dsamoht/mag-ont -profile <docker/singularity/apptainer> --input samplesheet.csv --outdir <OUTDIR>",
                showHidden: show_hidden,
                fullHelp  : help_full,
            ],
            help instanceof String && help != "true" ? help : "",
        ))
        // Nextflow creates the work directory when the session starts, before this script
        // runs, so printing the help message leaves an empty `work/` behind in whatever
        // directory it was called from. Remove it again, but only if this run is the one
        // that created it.
        if (workflow.workDir.exists() && workflow.workDir.list().size() == 0) {
            workflow.workDir.deleteDir()
        }
        exit(0)
    }

    //
    // Validate parameters and print a summary of the ones that differ from the defaults
    //
    if (validate_params) {
        validateParameters()
    }
    log.info(paramsSummaryLog(workflow))

    //
    // Read the sample sheet. Per-row validation lives in assets/schema_input.json;
    // nf-schema returns [ meta, assembly_fasta, long_reads, short_reads_1, short_reads_2 ]
    // with an empty list for any column left blank.
    //
    ch_samplesheet = channel
        .fromList(samplesheetToList(input, "${projectDir}/assets/schema_input.json"))
        .map { meta, assembly, long_reads, short_reads_1, short_reads_2 ->
            [
                sample_id     : meta.id,
                group         : meta.group,
                assembly      : assembly ?: false,
                assembly_path : assembly ? assembly.toString() : '',
                long_reads    : long_reads ?: false,
                sr1           : short_reads_1 ?: false,
                sr2           : short_reads_2 ?: false
            ]
        }

    //
    // Checks that span several rows of the sample sheet, which a per-row JSON schema
    // cannot express. Failures stop the pipeline before any task is submitted.
    //
    ch_samplesheet
        .map { sample -> [ sample.group, sample ] }
        .groupTuple()
        .map { group, rows -> validateGroup(group, rows) }

    emit:
    samplesheet = ch_samplesheet
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// Validate one group of samples: every group is assembled and binned as a unit, so the
// rows sharing a group have to agree with each other.
//
def validateGroup(group, rows) {
    def long_reads     = rows.collect { row -> row.long_reads }.findAll()
    def assemblies     = rows.collect { row -> row.assembly }.findAll()
    def assembly_paths = rows.collect { row -> row.assembly_path }.findAll()
    def short_reads    = rows.collect { row -> [ row.sr1, row.sr2 ] }.flatten().findAll()

    if (assemblies.isEmpty() && long_reads.isEmpty()) {
        error("group '${group}' has no assembly and no long reads to assemble")
    }

    // The same read file must not be claimed by two samples of the same group
    def path_to_samples = [:]
    rows.each { row ->
        [ row.long_reads, row.sr1, row.sr2 ].each { f ->
            if (f) {
                def p = f.toString()
                if (!path_to_samples[p]) {
                    path_to_samples[p] = []
                }
                path_to_samples[p] << row.sample_id
            }
        }
    }
    path_to_samples.each { path, ids ->
        if (ids.unique().size() > 1) {
            error("group '${group}' error: read file '${path}' is shared by multiple samples: ${ids.unique().join(', ')}")
        }
    }

    if (!assemblies.isEmpty()) {
        def unique_assembly_path = assembly_paths.unique()

        if (unique_assembly_path.size() > 1) {
            error("group '${group}' contains multiple different assemblies: ${unique_assembly_path.join(', ')} — only one unique assembly is allowed per group")
        }

        def samples_without_assembly = rows.findAll { row -> !row.assembly_path }
        if (!samples_without_assembly.isEmpty()) {
            def missing_samples = samples_without_assembly.collect { row -> row.sample_id }.join(', ')
            error("group '${group}' has inconsistent assembly assignment — some samples have assembly '${unique_assembly_path[0]}' but these samples are missing it: ${missing_samples}. All samples in a group must share the same assembly.")
        }

        if (long_reads.isEmpty() && short_reads.isEmpty()) {
            error("group '${group}' has assembly '${unique_assembly_path[0]}' but no reads (long or short) for binning")
        }
    }

    // Mapping strategy is chosen per group, so read types cannot be mixed within one
    if (rows.size() > 1) {
        def samples_with_only_long  = rows.findAll { row -> row.long_reads && !row.sr1 }
        def samples_with_only_short = rows.findAll { row -> !row.long_reads && row.sr1 && row.sr2 }

        if (!samples_with_only_long.isEmpty() && !samples_with_only_short.isEmpty()) {
            def long_samples  = samples_with_only_long.collect { row -> row.sample_id }.join(', ')
            def short_samples = samples_with_only_short.collect { row -> row.sample_id }.join(', ')
            error("group '${group}' mixes read types across samples. Samples with long reads: [${long_samples}]. Samples with paired-end reads: [${short_samples}].")
        }
    }

    return group
}
