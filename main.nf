nextflow.enable.dsl=2

params.sample_sheet   = null       // CSV: sample,fastq_s3
params.sample_glob    = null       // Alternative: s3://bucket/path/*.fastq.gz
params.alphabet       = 'ACGTN'
params.log_freq       = 1000
params.outdir         = 'results'  // Publish directory (point this at an S3 path in HealthOmics)
params.container      = null       // ECR image URI, e.g. 123456789012.dkr.ecr.eu-central-1.amazonaws.com/fastqwiper:0.1

// --------------------
// Input channel
// --------------------
Channel
    .choose( 
        { params.sample_sheet != null } : {
            Channel
                .fromPath(params.sample_sheet, checkIfExists: true)
                .splitCsv(header:true)
                .map { row ->
                    def s = row.sample as String
                    def p = row.fastq_s3 as String
                    tuple(s, path(p))
                }
        },
        { params.sample_glob != null } : {
            Channel
                .fromPath(params.sample_glob, checkIfExists: true)
                .map { f ->
                    def name = f.baseName.replaceAll(/\.fastq$|\.fq$|\.fastq\.gz$|\.fq\.gz$/,'')
                    tuple(name, f)
                }
        }
    )
    .set { reads_ch }

if( !reads_ch ) {
    exit 1, "Provide either --sample_sheet CSV or --sample_glob 's3://bucket/*.fastq.gz'"
}

// --------------------
// Processes
// --------------------

process FIX_GZRT {
    tag "$sample"
    publishDir "${params.outdir}/data", mode: 'copy'
    container params.container
    cpus 1
    memory '1.GB'
    errorStrategy 'terminate'

    input:
    tuple val(sample), path(reads)

    output:
    tuple val(sample), path("${sample}_fixed.fastq")

    script:
    """
    mkdir -p logs/fix_gzrt
    gzrecover -o ${sample}_fixed.fastq ${reads} -v 2> logs/fix_gzrt/fix_gzrt.${sample}.log
    """
}

process WIPE_FASTQ {
    tag "$sample"
    publishDir "${params.outdir}/data", mode: 'copy'
    container params.container
    cpus 2
    memory '4.GB'
    errorStrategy 'terminate'

    input:
    tuple val(sample), path(fixed_fastq)

    output:
    path("${sample}_fixed_wiped.fastq.gz")
    path("${sample}_final_summary.txt")
    path("logs/wipe_fastq/wipe_fastq.${sample}.log")

    script:
    """
    mkdir -p logs/wipe_fastq
    wipertools fastqwiper \
        --fastq_in ${fixed_fastq} \
        --fastq_out ${sample}_fixed_wiped.fastq.gz \
        --log_out ${sample}_final_summary.txt \
        --alphabet ${params.alphabet} \
        --log_frequency ${params.log_freq} \
        2> logs/wipe_fastq/wipe_fastq.${sample}.log
    """
}

workflow {
    reads_ch | FIX_GZRT | WIPE_FASTQ
}
