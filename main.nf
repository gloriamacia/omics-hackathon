nextflow.enable.dsl=2

params.input = null          // Direct path to FASTQ: s3://bucket/sample.fastq.gz
params.container = null      // ECR image URI
params.alphabet = 'ACGTN'    // default
params.log_freq = 1000      // default
params.outdir = 'results'    // default

// ---------- Inputs ----------
Channel
    .fromPath(params.input, checkIfExists: true)
    .map { f ->
        def name = f.baseName.replaceAll(/\.fastq$|\.fq$|\.fastq\.gz$|\.fq\.gz$/,'')
        tuple(name, f)
    }
    .set { reads_ch }

if( !reads_ch ) {
    exit 1, "Provide --input pointing to your FASTQ file"
}

// ---------- Processes ----------
process FIX_GZRT {
  tag "$sample"
  container params.container
  cpus 1
  memory '1.GB'
  errorStrategy 'terminate'
  publishDir params.outdir, mode: 'copy'

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
  container params.container
  cpus 2
  memory '4.GB'
  errorStrategy 'terminate'
  publishDir params.outdir, mode: 'copy'

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
